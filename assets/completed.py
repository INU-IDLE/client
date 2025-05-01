import json
import xml.etree.ElementTree as ET

def generate_stations(json_path, svg_path):
    with open(json_path, 'r', encoding='utf-8') as f:
        raw_data = json.load(f)

    # JSON 구조 보정 (상황에 따라 선택적 적용)
    if isinstance(raw_data, dict) and 'data' in raw_data:
        stations_info = raw_data['data']
    else:
        stations_info = raw_data

    # 사전 생성 로직
    station_dict = {}
    for item in stations_info:
        if isinstance(item, dict) and 'fr_code' in item:
            station_dict[item['fr_code']] = item

    # SVG 처리 (기존 코드 유지)
    tree = ET.parse(svg_path)
    root = tree.getroot()
    inkscape_ns = '{http://www.inkscape.org/namespaces/inkscape}'

    stations = []
    for elem in root.iter():
        label = elem.attrib.get(inkscape_ns + 'label')
        if label and label in station_dict:
            info = station_dict[label]
            cx = float(elem.attrib.get('cx', 0)) * 3.8
            cy = float(elem.attrib.get('cy', 0)) * 3.8
            r = float(elem.attrib.get('r', 10))

            stations.append(f'''  Station(
    id: "{label}",
    cx: {cx},
    cy: {cy},
    r: {r},
    stationNm: "{info['station_nm']}",
    line: "{info['line_num']}",
  ),''')

    return '\n'.join(stations)
