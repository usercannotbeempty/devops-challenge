"""Cross-layer regression: render the actual chart and compare to IRSA inputs.

No AWS calls. Run: python -m unittest discover -s tests -v
"""
import pathlib
import subprocess
import unittest

import hcl2
import yaml

ROOT = pathlib.Path(__file__).resolve().parents[1]


class ClaimsIdentityTest(unittest.TestCase):
    def test_rendered_worker_identity_matches_iam_in_each_environment(self):
        for environment in ("dev", "prod"):
            with self.subTest(environment=environment):
                cluster = ROOT / f"apps/acme-{environment}-cluster"
                helmfile = yaml.safe_load((cluster / "helmfile.yaml").read_text())
                release = next(r for r in helmfile["releases"] if r["name"] == "claims-worker")
                args = ["helm", "template", release["name"], str(cluster / release["chart"]),
                        "--namespace", release["namespace"]]
                for values_file in release["values"]:
                    args.extend(["-f", str(cluster / values_file)])
                rendered = subprocess.check_output(args, text=True)
                documents = [d for d in yaml.safe_load_all(rendered) if d]
                deployment = next(d for d in documents if d["kind"] == "Deployment")
                account = next(d for d in documents if d["kind"] == "ServiceAccount")
                path = ROOT / f"live/acme/ap-southeast-3/claims/{environment}/claims-worker-iam/terragrunt.hcl"
                with path.open() as source:
                    iam = hcl2.load(source)["inputs"]
                with (ROOT / "live/acme/account.hcl").open() as source:
                    account_id = hcl2.load(source)["locals"][0]["aws_account_id"]
                self.assertEqual(release["namespace"], iam["namespace"])
                self.assertEqual(account["metadata"]["name"], iam["service_account"])
                self.assertEqual(deployment["spec"]["template"]["spec"]["serviceAccountName"],
                                 iam["service_account"])
                self.assertEqual(account["metadata"]["annotations"]["eks.amazonaws.com/role-arn"],
                                 f"arn:aws:iam::{account_id}:role/{iam['name']}")

