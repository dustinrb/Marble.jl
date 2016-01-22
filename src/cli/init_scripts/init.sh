git init
git add .
git commit -m "Initial Commit"
echo mrbl >> .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit