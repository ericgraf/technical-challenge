
# framework
https://symfony.com/
https://github.com/symfony/symfony

## Example demo code
https://github.com/symfony/demo

# debug postgres directly

```
kubectl exec -it <clustername>-0 --psql -U postgres
\c app
\dt+
```
