FROM gitpod/workspace-postgres

RUN sudo wget https://julialang-s3.julialang.org/bin/linux/x64/1.8/julia-1.8.0-linux-x86_64.tar.gz \
  && tar -xvzf julia-1.8.0-linux-x86_64.tar.gz 
# Install direnv
RUN sudo apt-get update && sudo apt-get install -y direnv \
  && direnv hook bash >> /home/gitpod/.bashrc \
  && echo 'alias runjulia="GENIE_ENV=\"dev\" julia --project=$(pwd)"' >> /home/gitpod/.bashrc \
  && echo 'alias runtest="GENIE_ENV=\"dev\" julia --project=test bootstrap_tests.jl"' >> /home/gitpod/.bashrc \
  && mkdir -p .config/direnv \
  && echo '[whitelist]' > .config/direnv/config.toml \
  && echo 'prefix = [ "/workspace" ]' >> .config/direnv/config.toml 
  