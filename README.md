# tf-demo

```
docker build -t tf-demo .
docker run --rm -it -v $(pwd)/.vscode-server:/root/.vscode-server -v $(pwd)/:/tf-demo --name tf-demo tf-demo bash
```