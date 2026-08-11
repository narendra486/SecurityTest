from pathlib import Path

root = Path(__file__).resolve().parent
src = root / 'src'
src.mkdir(parents=True, exist_ok=True)

# Large JavaScript vulnerable sample with 1000+ lines
lines = []
lines.append("const express = require('express');")
lines.append("const app = express();")
lines.append("const crypto = require('crypto');")
lines.append("const { exec } = require('child_process');")
lines.append("")
lines.append("function evalUserInput(input) {")
lines.append("  return eval(input);")
lines.append("}")
lines.append("")
lines.append("function innerHtmlSink(value) {")
lines.append("  return `<div>${value}</div>`;")
lines.append("}")
lines.append("")
lines.append("function sqlInjection(userInput) {")
lines.append("  return `SELECT * FROM users WHERE name = '${userInput}'`;")
lines.append("}")
lines.append("")
lines.append("function hardcodedSecret() {")
lines.append("  return 'AKIAEXAMPLE1234567890ABC';")
lines.append("}")
lines.append("")
lines.append("function commandInjection(command) {")
lines.append("  return exec(command);")
lines.append("}")
lines.append("")
lines.append("function weakHash(data) {")
lines.append("  return crypto.createHash('md5').update(data).digest('hex');")
lines.append("}")
lines.append("")
for i in range(1, 401):
    lines.append(f"function vulnPattern{i}(value) {{")
    lines.append(f"  const marker = 'marker-{i}';")
    lines.append(f"  const combined = value + marker;")
    lines.append(f"  return combined;")
    lines.append("}")
    lines.append("")
for i in range(1, 401):
    lines.append(f"function vulnerableBlock{i}(input) {{")
    lines.append(f"  const secret = 'token-{i}';")
    lines.append(f"  return input + secret;")
    lines.append("}")
    lines.append("")
for i in range(1, 301):
    lines.append(f"function riskyLogic{i}(param) {{")
    lines.append(f"  const output = param + 'risk-{i}';")
    lines.append(f"  return output;")
    lines.append("}")
    lines.append("")
lines.append("app.get('/', (req, res) => {")
lines.append("  res.send(evalUserInput(req.query.input));")
lines.append("});")
lines.append("")
lines.append("app.get('/search', (req, res) => {")
lines.append("  res.send(sqlInjection(req.query.q));")
lines.append("});")
lines.append("")
lines.append("app.get('/secret', (req, res) => {")
lines.append("  res.send(hardcodedSecret());")
lines.append("});")
lines.append("")
lines.append("app.get('/run', (req, res) => {")
lines.append("  res.send(commandInjection(req.query.cmd));")
lines.append("});")
lines.append("")
lines.append("app.listen(3000, () => console.log('listening'));")
(src / 'code.js').write_text('\n'.join(lines) + '\n', encoding='utf-8')

# Large Terraform sample
terraform_lines = []
terraform_lines.append('resource "aws_s3_bucket" "demo" {')
terraform_lines.append('  bucket = "demo-bucket"')
terraform_lines.append('  acl    = "public-read"')
terraform_lines.append('}')
terraform_lines.append('')
for i in range(1, 51):
    terraform_lines.append(f'resource "aws_security_group" "sg{i}" {{')
    terraform_lines.append(f'  name = "sg{i}"')
    terraform_lines.append('  ingress {')
    terraform_lines.append('    from_port   = 0')
    terraform_lines.append('    to_port     = 0')
    terraform_lines.append('    protocol    = "-1"')
    terraform_lines.append('    cidr_blocks = ["0.0.0.0/0.0.0.0"]')
    terraform_lines.append('  }')
    terraform_lines.append('}')
    terraform_lines.append('')
(src / 'main.tf').write_text('\n'.join(terraform_lines) + '\n', encoding='utf-8')

# Large secrets sample
secrets_lines = []
for i in range(1, 251):
    secrets_lines.append(f'API_KEY_{i} = "ghp_example_{i}_token"')
for i in range(251, 401):
    secrets_lines.append(f'SECRET_{i} = "AKIAEXAMPLE{i}ABC"')
(src / 'secrets.txt').write_text('\n'.join(secrets_lines) + '\n', encoding='utf-8')

# Large dependency sample
dep_lines = ['{']
for i in range(1, 151):
    dep_lines.append(f'  "pkg{i}": "1.0.0",')
dep_lines[-1] = dep_lines[-1].rstrip(',')
dep_lines.append('}')
(src / 'dependencies.json').write_text('\n'.join(dep_lines) + '\n', encoding='utf-8')

# Larger Dockerfile sample
docker_lines = ['FROM ubuntu:20.04']
for i in range(1, 151):
    docker_lines.append(f'RUN echo "line-{i}"')
docker_lines.append('RUN chmod 777 /tmp')
docker_lines.append('RUN useradd root')
(src / 'Dockerfile.sample').write_text('\n'.join(docker_lines) + '\n', encoding='utf-8')
