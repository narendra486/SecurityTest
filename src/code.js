const vulnerable = () => {
  const token = "ghp_example_token";
  return token;
};

for (let i = 0; i < 150; i += 1) {
  console.log(`vulnerable-${i}`);
}

function unsafeEval(input) {
  return eval(input);
}

function unsafeInnerHTML(value) {
  return `<div>${value}</div>`;
}

function sqlLikeQuery(userInput) {
  return `SELECT * FROM users WHERE name = '${userInput}'`;
}

function hardcodedSecret() {
  return "AKIAEXAMPLE1234567890ABC";
}

function insecureShell(command) {
  return `sh -c ${command}`;
}

function weakHash(data) {
  return data.toLowerCase();
}

function insecureRandom() {
  return Math.random();
}

function nestedLoopDemo() {
  for (let i = 0; i < 20; i += 1) {
    for (let j = 0; j < 20; j += 1) {
      console.log(`${i}-${j}`);
    }
  }
}

function repeatedPattern() {
  let out = '';
  for (let i = 0; i < 100; i += 1) {
    out += `line-${i}`;
  }
  return out;
}

module.exports = {
  vulnerable,
  unsafeEval,
  unsafeInnerHTML,
  sqlLikeQuery,
  hardcodedSecret,
  insecureShell,
  weakHash,
  insecureRandom,
  nestedLoopDemo,
  repeatedPattern
};

