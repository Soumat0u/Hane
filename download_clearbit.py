import urllib.request
import os

banks = {
    'yapi_kredi': 'https://logo.clearbit.com/yapikredi.com.tr',
    'is_bankasi': 'https://logo.clearbit.com/isbank.com.tr',
    'vakif': 'https://logo.clearbit.com/vakifbank.com.tr'
}

os.makedirs('assets/images/logos', exist_ok=True)

for name, url in banks.items():
    try:
        print(f'Downloading {name} from {url}')
        req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'})
        with urllib.request.urlopen(req) as response:
            with open(f'assets/images/logos/{name}.png', 'wb') as f:
                f.write(response.read())
        print(f'Success: {name}.png')
    except Exception as e:
        print(f'Failed to download {name}: {e}')
