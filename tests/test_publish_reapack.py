import importlib.util
import json
import os
from pathlib import Path
import re
import tempfile
import unittest
from unittest.mock import patch
import xml.etree.ElementTree as ET

ROOT=Path(__file__).resolve().parents[1]
spec=importlib.util.spec_from_file_location('publisher',ROOT/'tools/publish_reapack.py')
publisher=importlib.util.module_from_spec(spec);spec.loader.exec_module(publisher)
BASE='''<?xml version="1.0"?><index version="1" name="Collection">
  <category name="Audio">
    <reapack name="Stable installed name.lua" type="script" desc="Useful action">
      <version name="1.2.3" author="Andrey Novikov" time="2026-01-01T00:00:00Z">
        <source file="Stable installed name.lua" main="main">https://raw.githubusercontent.com/andreynovikov86-cmd/ReaScripts/aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa/action.lua</source>
      </version>
    </reapack>
  </category>
</index>'''
class PublishTests(unittest.TestCase):
 def setUp(self):
  self.temp=tempfile.TemporaryDirectory();self.cwd=Path.cwd();os.chdir(self.temp.name)
  Path('index.xml').write_text(BASE);self.old='-- @description Useful action\n-- @version 1.2.3\nreturn 1\n';Path('action.lua').write_text(self.old)
 def tearDown(self):os.chdir(self.cwd);self.temp.cleanup()
 def prepare(self):
  with patch.object(publisher.subprocess,'check_output',return_value=self.old.encode()):publisher.prepare()
  return json.loads(publisher.PENDING.read_text())
 def test_unchanged_skips_release(self):
  self.assertEqual(self.prepare(),[]);self.assertEqual(Path('index.xml').read_text(),BASE)
 def test_changed_source_gets_patch_version(self):
  Path('action.lua').write_text(self.old.replace('return 1','return 2'))
  item=self.prepare()[0];self.assertEqual(item['version'],'1.2.4');self.assertIn('@version 1.2.4',Path('action.lua').read_text())
  result=publisher.append_release(BASE,item,'b'*40)
  old_block=re.search(r'      <version[\s\S]*?      </version>',BASE)[0];self.assertIn(old_block,result)
  package=ET.fromstring(result).find('category/reapack');self.assertEqual(package.get('name'),'Stable installed name.lua')
  latest=package.findall('version')[-1];self.assertEqual(latest.get('name'),'1.2.4');self.assertIn('/'+'b'*40+'/',latest.find('source').text)
 def test_explicit_version_is_retained(self):
  Path('action.lua').write_text(self.old.replace('1.2.3','2.0.0'))
  self.assertEqual(self.prepare()[0]['version'],'2.0.0')
 def test_new_script_and_xml_escaping(self):
  Path('new.lua').write_text('-- @description A & B\n-- @version 1.0.0\nreturn 0\n')
  item=next(x for x in self.prepare() if x['package']=='new.lua');result=publisher.append_release(BASE,item,'c'*40)
  self.assertEqual(ET.fromstring(result).find("category[@name='Other']/reapack").get('desc'),'A & B')
 def test_version_reversal_is_refused(self):
  Path('action.lua').write_text(self.old.replace('1.2.3','1.2.2'))
  with self.assertRaises(AssertionError):self.prepare()
  self.assertEqual(Path('index.xml').read_text(),BASE)
if __name__=='__main__':unittest.main()
