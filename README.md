### A playbook to get up and running on Linode

I couldn't install ansible on my work pc. This is a workaround

1.  wget https://raw.githubusercontent.com/guinslym/linode_ansible_quickstart_server/main/quickstart.sh
2.  chmod 777 quickstart.sh
3.  sudo bash quickstart.sh
  
  
medipack trim input.mp4 -s 01:04 -e 14:08 -o output.mp4

# SSH key uploads
1.  mv ssh-keys/* .ssh/
2.  cd !$
3.  chmod 600 ask_a_librarian
4.  eval "$(ssh-agent -s)"
5.  ssh-add ~/.ssh/ask_a_librarian
6.  ssh -T git@github.com
