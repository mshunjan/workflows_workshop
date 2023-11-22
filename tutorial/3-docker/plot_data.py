#!/usr/bin/env python

import pandas as pd
import plotly.express as px
import plotly.graph_objects as go
import argparse, sys

def get_data(path, sep):
    return pd.read_csv(filepath_or_buffer=path, sep=sep)

def visualize_data(df, outdir):
    # Drop unnecessary columns
    df.drop(columns=["taxonomy_id", "taxonomy_lvl"], inplace=True)
    df = df.loc[:, ~df.columns.str.contains("_num")]

    # Rename and melt columns
    new_columns = {"name": "Species", "variable": "Sample", "value": "Fraction Abundance"}
    new_df = df.melt(id_vars="name").rename(columns=new_columns)

    # Generate express chart and add traces to go plot
    figx = px.bar(new_df, x="Sample", y="Fraction Abundance", color="Species")
    fig = go.Figure(data=figx.data)

   
    fig.update_layout(
        barmode="stack",
        xaxis_title="Samples",
        yaxis_title="Fraction Abundance (%)",
    )
    # Save graph to file
    with open(outdir, "w") as f:
        f.write(fig.to_html(full_html=False, include_plotlyjs="cdn"))


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("-i", "--data", nargs=2, help="Data for generating plot")

    parser.add_argument("-o", "--outdir", dest="outdir", help="Output location")

    args = parser.parse_args()

    sys.stdout.write("Reading your data\n")

    data = get_data(args.data[0], args.data[1])
    outdir = args.outdir

    if ".html" not in args.outdir:
        raise argparse.ArgumentTypeError("must be an html file")

    visualize_data(data, outdir)
    sys.stdout.write("Successfully created a plot!\n")


if __name__ == "__main__":
    main()
