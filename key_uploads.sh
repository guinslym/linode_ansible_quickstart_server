mv ssh-keys/* ~/.ssh/
cd ~/.ssh/
chmod 600 ask_a_librarian
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/ask_a_librarian
ssh -T git@github.com
