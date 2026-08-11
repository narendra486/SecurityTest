from pathlib import Path

root = Path(__file__).resolve().parent.parent
samples = root / 'samples'
(samples / 'code').mkdir(parents=True, exist_ok=True)
(samples / 'secret').mkdir(parents=True, exist_ok=True)
(samples / 'iac').mkdir(parents=True, exist_ok=True)
(samples / 'dependency').mkdir(parents=True, exist_ok=True)
(samples / 'image').mkdir(parents=True, exist_ok=True)

code_lines = []
for i in range(1, 301):
    code_lines.append(f'def vulnerable_func_{i}(value):\n    secret = "ghp_example_{i}_token"\n    return str({i}) + value + secret\n')
(samples / 'code' / 'sample_code.py').write_text(''.join(code_lines) + '\n', encoding='utf-8')

secret_lines = []
for i in range(1, 301):
    secret_lines.append(f'API_KEY_{i} = "ghp_example_{i}_token"')
(samples / 'secret' / 'sample_secrets.txt').write_text('\n'.join(secret_lines) + '\n', encoding='utf-8')

iac_lines = []
for i in range(1, 301):
    iac_lines.append(f'resource "aws_s3_bucket" "bucket{i}" {{\n  bucket = "bucket-{i}"\n  acl    = "public-read"\n}}')
(samples / 'iac' / 'sample_iac.tf').write_text('\n'.join(iac_lines) + '\n', encoding='utf-8')

dep_lines = []
for i in range(1, 301):
    dep_lines.append(f'  "pkg{i}": "1.0.0"')
(samples / 'dependency' / 'sample_dependencies.json').write_text('{\n' + ',\n'.join(dep_lines) + '\n}\n', encoding='utf-8')

image_lines = ['FROM ubuntu:20.04']
for i in range(1, 301):
    image_lines.append(f'RUN apt-get install -y curl{i}')
(samples / 'image' / 'Dockerfile.sample').write_text('\n'.join(image_lines) + '\n', encoding='utf-8')
