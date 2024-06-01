FROM gitpod/workspace-postgres
ARG JULIA_URL="https://julialang-s3.julialang.org/bin/linux/x64/1.10/julia-1.10.3-linux-x86_64.tar.gz" 
ARG JULIA_MINOR_VERSION="1.10"
ARG JULIA_BUGFIX_VERSION="1.10.3"

RUN sudo apt-get update && sudo apt-get install -y direnv \
  && direnv hook bash >> /home/gitpod/.bashrc \
  && echo "export PATH=/home/gitpod/julia/bin:$PATH" >> /home/gitpod/.bashrc
RUN sudo curl -L "${JULIA_URL}" | tar -xzf - \
  && mv julia-${JULIA_BUGFIX_VERSION} julia 
RUN export PATH=/home/gitpod/julia/bin:$PATH \
  && julia -e "using Pkg; Pkg.add(\"IJulia\")"
  
