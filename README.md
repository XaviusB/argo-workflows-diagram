# argo-workflows-diagram

Create DAG or steps diagram in png and drawio format.

It helps debugging and optimizing complexe dag or very long steps

```sh
for f in workflows/*.yml; do tree.sh input_file="${f}"; done

[2023-06-17 04:29:50] INFO: processing /home/xavier/workflows/test.yml (main)
Creating DAG diagram
[2023-06-17 04:29:51] WARN: Diagram here: /home/xavier/workflows/test.png (main)
[2023-06-17 04:29:51] WARN: Drawio here: /home/xavier/workflows/test.drawio (main)
```
