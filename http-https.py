import xml.etree.ElementTree as ET

tree = ET.parse('raj.xml')
root = tree.getroot()

def removeHostname():
    for host in root.iter('host'):
        for elem in host.iter():
            if 'name' in elem.attrib and elem.attrib['name'] == 'ISP_redir_site':
                root.remove(host)

removeHostname()
tree.write('output.xml')
