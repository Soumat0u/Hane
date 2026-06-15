import urllib.request
import json
import os

banks = {
    'ziraat': 'File:Ziraat_Bankas%C4%B1_logo.png',
    'garanti': 'File:Logo_garanti_bbva.jpg',
    'halk': 'File:Halkbank_logo.svg',
    'akbank': 'File:Akbank_logo.svg',
    'yapi_kredi': 'File:Yap%C4%B1_Kredi_logo.svg',
    'is_bankasi': 'File:%C4%B0%C5%9F_Bankas%C4%B1_logo.svg',
    'vakif': 'File:Vak%C4%B1fBank_logo.svg'
}

os.makedirs('assets/images/logos', exist_ok=True)

for name, filename in banks.items():
    try:
        url = f'https://commons.wikimedia.org/w/api.php?action=query&titles={filename}&prop=imageinfo&iiprop=url&iiurlwidth=250&format=json'
        req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
        with urllib.request.urlopen(req) as response:
            data = json.loads(response.read())
            pages = data['query']['pages']
            for page_id in pages:
                if 'imageinfo' in pages[page_id]:
                    thumb_url = pages[page_id]['imageinfo'][0]['thumburl']
                    print(f'Downloading {name} from {thumb_url}')
                    req_img = urllib.request.Request(thumb_url, headers={'User-Agent': 'Mozilla/5.0'})
                    with urllib.request.urlopen(req_img) as img_resp:
                        with open(f'assets/images/logos/{name}.png', 'wb') as f:
                            f.write(img_resp.read())
    except Exception as e:
        print(f'Failed to download {name}: {e}')
