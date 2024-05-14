FROM gitpod/workspace-postgres
# Install direnv
RUN sudo apt-get update && sudo apt-get install -y direnv \
  && direnv hook bash >> /home/gitpod/.bashrc
  
