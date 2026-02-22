def normalize_column(df):
    df.columns= (
        df.columns
            .str.strip()
            .str.lower()
            .str.replace(r"\(.*\)", "", regex=True)
            .str.replace(r"[^\w\s]", "", regex=True)
            .str.replace(r"\s+", "_", regex=True)
            .str.replace(r"_+", "_", regex=True)

    )
    return df
    