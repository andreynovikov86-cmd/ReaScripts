#!/usr/bin/env python3
"""Append immutable ReaPack releases; preserve package identities and old versions."""
from pathlib import Path
from datetime import datetime,timezone
from urllib.parse import urlparse,unquote
from zipfile import ZipFile,ZipInfo,ZIP_DEFLATED
import argparse,html,json,re,subprocess
import xml.etree.ElementTree as ET

OWNER='andreynovikov86-cmd'
REPO='ReaScripts'
PENDING=Path('.reapack-pending.json')
VERSION=re.compile(r'^--\s*@version\s+(\S+)',re.M)

def version_key(value):
    assert re.fullmatch(r'\d+(?:\.\d+){1,3}',value),f'Unsupported version: {value}'
    return tuple(int(x) for x in value.split('.'))

def bump(value):
    fields=list(version_key(value))
    while len(fields)<3:fields.append(0)
    fields[-1]+=1
    return '.'.join(map(str,fields))

def source_path(url):
    parts=unquote(urlparse(url).path).strip('/').split('/')
    assert parts[:2]==[OWNER,REPO],f'Unexpected source repository: {url}'
    if parts[2]=='raw':parts.pop(2)
    assert re.fullmatch('[a-f0-9]{40}',parts[2]),'Source must use an immutable commit'
    path='/'.join(parts[3:]);assert path and '..' not in Path(path).parts
    return parts[2],path

def changelog(content):
    match=re.search(r'^--\s*@changelog\s*\n((?:--[^\n]*\n)*)',content,re.M)
    if not match:return 'Update script.'
    return '\n'.join(re.sub(r'^--\s*','',line) for line in match[1].splitlines()).strip() or 'Update script.'

def prepare():
    root=ET.parse('index.xml').getroot();pending=[];known=set()
    for category in root.findall('category'):
        for package in category.findall('reapack'):
            releases=package.findall('version')
            if not releases:continue
            latest=max(releases,key=lambda x:version_key(x.get('name')))
            sources=latest.findall('source');main=next((s for s in sources if 'main' in s.get('main','').split()),None)
            if main is None:continue
            sha,path=source_path(main.text);known.add(path);file=Path(path)
            if not file.is_file():continue
            content=file.read_text();match=VERSION.search(content);assert match,f'Missing @version: {path}'
            current,previous=match[1],latest.get('name');assert version_key(current)>=version_key(previous),f'Version went backwards: {path}'
            old=subprocess.check_output(['git','show',f'{sha}:{path}']).decode('utf-8')
            if current==previous and content==old:continue
            if current==previous:
                current=bump(previous);content=VERSION.sub('-- @version '+current,content,count=1);file.write_text(content)
            entries=[]
            for s in sources:
                _,provided=source_path(s.text);assert Path(provided).is_file(),f'Missing provided file: {provided}'
                entries.append({'path':provided,'attributes':dict(s.attrib)})
            pending.append({'category':category.get('name'),'package':package.get('name'),'version':current,'description':package.get('desc'),'sources':entries,'changelog':changelog(content)})
    for file in sorted(Path('.').glob('*.lua')):
        path=file.as_posix()
        if path in known:continue
        content=file.read_text();match=VERSION.search(content);description=re.search(r'^--\s*@description\s+(.+)',content,re.M)
        if not match or not description:continue
        version_key(match[1]);pending.append({'category':'Other','package':file.name,'version':match[1],'description':description[1].strip(),'sources':[{'path':path,'attributes':{'file':file.name,'main':'main'}}],'changelog':changelog(content)})
    PENDING.write_text(json.dumps(pending,ensure_ascii=False,indent=2))
    print(f'{len(pending)} script release(s) prepared.')

def append_release(index,item,sha):
    assert re.fullmatch('[0-9a-f]{40}',sha)
    category_pattern=r'  <category name="'+re.escape(html.escape(item['category'],quote=True))+r'">[\s\S]*?  </category>'
    category=re.search(category_pattern,index)
    if category is None:
        block=f'  <category name="{html.escape(item["category"],quote=True)}">\n  </category>\n'
        index=index.replace('</index>',block+'</index>');category=re.search(category_pattern,index)
    body=category[0];package_pattern=r'    <reapack name="'+re.escape(html.escape(item['package'],quote=True))+r'"[^>]*>[\s\S]*?    </reapack>'
    package=re.search(package_pattern,body)
    if package is None:
        block=f'    <reapack name="{html.escape(item["package"],quote=True)}" type="script" desc="{html.escape(item["description"],quote=True)}">\n    </reapack>\n'
        body=body.replace('  </category>',block+'  </category>');package=re.search(package_pattern,body)
    assert not ET.fromstring(package[0]).findall(f'version[@name="{item["version"]}"]'),'Release already exists'
    when=datetime.now(timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ')
    release=f'      <version name="{item["version"]}" author="Andrey Novikov" time="{when}">\n        <changelog>{html.escape(item["changelog"])}</changelog>\n'
    from urllib.parse import quote
    for source in item['sources']:
        attributes=''.join(' '+k+'="'+html.escape(v,quote=True)+'"' for k,v in source['attributes'].items())
        url=f'https://raw.githubusercontent.com/{OWNER}/{REPO}/{sha}/{quote(source["path"])}'
        release+=f'        <source{attributes}>{url}</source>\n'
    release+='      </version>\n'
    replacement=package[0].replace('    </reapack>',release+'    </reapack>')
    body=body.replace(package[0],replacement,1);index=index.replace(category[0],body,1);ET.fromstring(index)
    return index

def build(sha):
    index=Path('index.xml').read_text()
    for item in json.loads(PENDING.read_text()):index=append_release(index,item,sha)
    Path('index.xml').write_text(index)
    # A complete deterministic manual download; never include personal bank files.
    names=['Articulation_Manager.lua','Articulation_Editor.lua','Articulation_Quick_Menu.lua','Articulation_Menu_Popup.lua','USER_GUIDE.md','USER_GUIDE_RU.md','INSTALL_RU.txt','LICENSE.md','THIRD_PARTY_NOTICES.txt','README.md','README_RU.md']
    Path('downloads').mkdir(exist_ok=True)
    with ZipFile('downloads/ArticulationBox.zip','w',ZIP_DEFLATED) as archive:
        for name in names:
            info=ZipInfo('ArticulationBox/'+name,(2026,1,1,0,0,0));info.compress_type=ZIP_DEFLATED
            archive.writestr(info,(Path('ArticulationBox')/name).read_bytes())
    PENDING.unlink()
    print('ReaPack index and manual ArticulationBox download are ready.')

if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__);parser.add_argument('command',choices=['prepare','build']);parser.add_argument('--source-sha');args=parser.parse_args()
    if args.command=='prepare':prepare()
    else:build(args.source_sha)
