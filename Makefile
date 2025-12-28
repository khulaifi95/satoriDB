BIGANN_BASE_URL = ftp://ftp.irisa.fr/local/texmex/corpus/bigann_base.bvecs.gz
BIGANN_QUERY_URL = ftp://ftp.irisa.fr/local/texmex/corpus/bigann_query.bvecs.gz
BIGANN_GND_URL = ftp://ftp.irisa.fr/local/texmex/corpus/bigann_gnd.tar.gz

SIFT1M_URL = ftp://ftp.irisa.fr/local/texmex/corpus/sift.tar.gz

DATA_DIR ?= .
BASE = $(DATA_DIR)/bigann_base.bvecs.gz
QUERY = $(DATA_DIR)/bigann_query.bvecs.gz
GND = $(DATA_DIR)/bigann_gnd.tar.gz
BASE_F32 = $(DATA_DIR)/bigann_base.bvecs.f32bin

SIFT1M_ARCHIVE = $(DATA_DIR)/sift.tar.gz
SIFT1M_DIR = $(DATA_DIR)/sift
SIFT1M_BASE = $(SIFT1M_DIR)/sift_base.fvecs
SIFT1M_QUERY = $(SIFT1M_DIR)/sift_query.fvecs
SIFT1M_BASE_F32 = $(DATA_DIR)/sift_base.fvecs.f32bin

CARGO ?= cargo

.PHONY: bigann-download bigann-prepare benchmark clean-benchmark-data sift1m-download sift1m-prepare benchmark-small

bigann-download: warn-benchmark-space $(BASE) $(QUERY) $(GND)

warn-benchmark-space:
	@echo "WARNING: Benchmark assets (downloads + extracted) can exceed 1TB total disk usage."
	@echo "Ensure you have enough space before continuing."

$(BASE):
	curl -fL --progress-bar $(BIGANN_BASE_URL) -o $@

$(QUERY):
	curl -fL --progress-bar $(BIGANN_QUERY_URL) -o $@

$(GND):
	curl -fL --progress-bar $(BIGANN_GND_URL) -o $@

bigann-prepare: $(BASE_F32)

$(BASE_F32): $(BASE)
	$(CARGO) run --release --bin prepare_dataset -- $< $@

benchmark: bigann-download bigann-prepare
	SATORI_RUN_BENCH=1 $(CARGO) run --release --bin satoridb

# SIFT1M Targets (Smaller dataset ~150MB)
sift1m-download: warn-sift1m-space $(SIFT1M_BASE)

warn-sift1m-space:
	@echo "WARNING: SIFT1M assets (downloads + extracted) will occupy ~200MB of disk space."
	@echo "Ensure you have enough space before continuing."

$(SIFT1M_ARCHIVE):
	curl -fL --progress-bar $(SIFT1M_URL) -o $@

$(SIFT1M_BASE): $(SIFT1M_ARCHIVE)
	tar -xzvf $< -C $(DATA_DIR)
	touch $@

sift1m-prepare: $(SIFT1M_BASE_F32)

$(SIFT1M_BASE_F32): $(SIFT1M_BASE)
	$(CARGO) run --release --bin prepare_dataset -- $< $@

benchmark-small: sift1m-download sift1m-prepare
	SATORI_RUN_BENCH=1 $(CARGO) run --release --bin satoridb

clean-benchmark-data:
	rm -f $(BASE) $(BASE_F32) $(QUERY) $(GND)
	rm -f $(SIFT1M_ARCHIVE) $(SIFT1M_BASE_F32)
	rm -rf $(SIFT1M_DIR)
