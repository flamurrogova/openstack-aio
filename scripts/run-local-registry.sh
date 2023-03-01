docker run -d -p 5000:5000 -v $(pwd)/registry:/var/lib/registry --restart=always --name registry registry:2
