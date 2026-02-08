# ベースイメージ: miniforge3 (conda/mambaが入った軽量Linux)
FROM docker.io/condaforge/miniforge3:latest

# CadQueryをインストール
RUN mamba install -y -c conda-forge cadquery \
    && mamba clean -afy

# 作業ディレクトリを設定
WORKDIR /work

# コンテナ起動時にpythonを実行
ENTRYPOINT ["python"]
