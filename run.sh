podman run -it --device=/dev/kfd --device=/dev/dri -p 0.0.0.0:7860:7860 -v ./data:/data localhost/rocm
