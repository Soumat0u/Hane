import urllib.request
import os

banks = {
    'yapi_kredi': 'https://t2.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=http://www.yapikredi.com.tr&size=256',
    'is_bankasi': 'https://t2.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=http://www.isbank.com.tr&size=256',
    'vakif': 'https://t2.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=http://www.vakifbank.com.tr&size=256'
}

os.makedirs('assets/images/logos', exist_ok=True)

for name, url in banks.items():
    try:
        print(f'Downloading {name} from Google Favicon...')
        req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
        with urllib.request.urlopen(req) as response:
            with open(f'assets/images/logos/{name}.png', 'wb') as f:
                f.write(response.read())
        print(f'Success: {name}.png')
    except Exception as e:
        print(f'Failed to download {name}: {e}')
