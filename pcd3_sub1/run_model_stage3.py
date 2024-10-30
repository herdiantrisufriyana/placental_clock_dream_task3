from utils import load_and_predict, load_and_predict_probabilities
import argparse

# Set up the argument parser
parser = argparse.ArgumentParser(description="Predict gestational age using a pre-trained model.")
parser.add_argument("--input", type=str, default="/input", help="Input directory [default=/input]")
parser.add_argument("--output", type=str, default="/output", help="Output directory [default=/output]")
parser.add_argument("--data", type=str, default="data", help="Data directory [default=data]")
parser.add_argument("--extdata", type=str, default="inst/extdata", help="Extension data directory [default=inst/extdata]")
parser.add_argument("--intermediate", type=str, default="intermediate", help="Intermediate data directory [default=intermediate]")
args = parser.parse_args()

extdata = args.extdata
intermediate = args.intermediate

prefix = 'ga_est'
load_and_predict(prefix, extdata, intermediate)

prefix = 'ga_res_conds_pred_est'
load_and_predict(prefix, extdata, intermediate)

prefix = 'ga_res_comb_pr_est'
load_and_predict(prefix, extdata, intermediate)

prefix = 'ga_res_comb_tb_est'
load_and_predict(prefix, extdata, intermediate)
