const vulnerable = () => {
  const token = "ghp_example_token";
  return token;
};

for (let i = 0; i < 400; i += 1) {
  console.log(`vulnerable-${i}`);
}
