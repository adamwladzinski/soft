#
# Topology for AppoloLake with headset on SSP2, spk on SSP1 and DMIC capture
#

# Include topology builder
include(`utils.m4')
include(`dai.m4')
include(`pipeline.m4')
include(`ssp.m4')

# Include TLV library
include(`common/tlv.m4')

# Include Token library
include(`sof/tokens.m4')

# Include bxt DSP configuration
include(`platform/intel/bxt.m4')
include(`platform/intel/dmic.m4')

#
# Define the pipelines
#
# PCM0 ----> volume -----> SSP1 (speaker - maxim98357a)
# PCM1 <---> volume <----> SSP2 (headset - da7219)
# PCM99 <---- volume <----- DMIC0 (dmic capture)
#

# Low Latency playback pipeline 1 on PCM 0 using max 2 channels of s32le.
# Schedule 48 frames per 1000us deadline on core 0 with priority 0
PIPELINE_PCM_ADD(sof/pipe-volume-playback.m4,
	1, 0, 2, s32le,
	48, 1000, 0, 0)

# Low Latency playback pipeline 2 on PCM 1 using max 2 channels of s32le.
# Schedule 48 frames per 1000us deadline on core 0 with priority 0
PIPELINE_PCM_ADD(sof/pipe-volume-playback.m4,
	2, 1, 2, s32le,
	48, 1000, 0, 0)

# Low Latency capture pipeline 3 on PCM 1 using max 2 channels of s32le.
# Schedule 48 frames per 1000us deadline on core 0 with priority 0
PIPELINE_PCM_ADD(sof/pipe-volume-capture.m4,
	3, 1, 2, s32le,
	48, 1000, 0, 0)

# Low Latency capture pipeline 4 on PCM 0 using max 4 channels of s32le.
# Schedule 48 frames per 1000us deadline on core 0 with priority 0
#PIPELINE_PCM_ADD(sof/pipe-volume-capture.m4,
PIPELINE_PCM_ADD(sof/pipe-passthrough-capture.m4,
	4, 99, 4, s32le,
	48, 1000, 0, 0)

#
# DAIs configuration
#

# playback DAI is SSP1 using 2 periods
# Buffers use s16le format, with 48 frame per 1000us on core 0 with priority 0
DAI_ADD(sof/pipe-dai-playback.m4,
	1, SSP, 1, SSP1-Codec,
	PIPELINE_SOURCE_1, 2, s16le,
	48, 1000, 0, 0)

# playback DAI is SSP1 using 2 periods
# Buffers use s16le format, with 48 frame per 1000us on core 0 with priority 0
DAI_ADD(sof/pipe-dai-playback.m4,
	2, SSP, 2, SSP2-Codec,
	PIPELINE_SOURCE_2, 2, s16le,
	48, 1000, 0, 0)

# capture DAI is SSP1 using 2 periods
# Buffers use s16le format, with 48 frame per 1000us on core 0 with priority 0
DAI_ADD(sof/pipe-dai-capture.m4,
	3, SSP, 2, SSP2-Codec,
	PIPELINE_SINK_3, 2, s16le,
	48, 1000, 0, 0)

# capture DAI is DMIC0 using 2 periods
# Buffers use s16le format, with 48 frame per 1000us on core 0 with priority 0
DAI_ADD(sof/pipe-dai-capture.m4,
	4, DMIC, 0, dmic01,
	PIPELINE_SINK_4, 2, s32le,
	48, 1000, 0, 0)

PCM_PLAYBACK_ADD(Speakers, 0, PIPELINE_PCM_1)
PCM_DUPLEX_ADD(Headset, 1, PIPELINE_PCM_2, PIPELINE_PCM_3)
PCM_CAPTURE_ADD(DMIC01, 99, PIPELINE_PCM_4)

#
# BE configurations - overrides config in ACPI if present
#

#SSP 1 (ID: 0) with 19.2 MHz mclk with MCLK_ID 1 (unused), 1.536 MHz blck
DAI_CONFIG(SSP, 1, 0, SSP1-Codec,
	SSP_CONFIG(I2S, SSP_CLOCK(mclk, 19200000, codec_mclk_in),
		SSP_CLOCK(bclk, 1536000, codec_slave),
		SSP_CLOCK(fsync, 48000, codec_slave),
		SSP_TDM(2, 16, 3, 3),
		SSP_CONFIG_DATA(SSP, 1, 16, 1)))

#SSP 2 (ID: 1) with 19.2 MHz mclk with MCLK_ID 1, 1.92 MHz bclk
DAI_CONFIG(SSP, 2, 1, SSP2-Codec,
	SSP_CONFIG(I2S, SSP_CLOCK(mclk, 19200000, codec_mclk_in),
		SSP_CLOCK(bclk, 1920000, codec_slave),
		SSP_CLOCK(fsync, 48000, codec_slave),
		SSP_TDM(2, 20, 3, 3),
		SSP_CONFIG_DATA(SSP, 2, 16, 1)))

# dmic01 (id: 2)
DAI_CONFIG(DMIC, 0, 2, dmic01,
	DMIC_CONFIG(1, 500000, 4800000, 40, 60, 48000,
		DMIC_WORD_LENGTH(s32le), DMIC, 0,
		# FIXME: what is the right configuration
		# PDM_CONFIG(DMIC, 0, FOUR_CH_PDM0_PDM1)))
		PDM_CONFIG(DMIC, 0, STEREO_PDM0)))

## remove warnings with SST hard-coded routes (FIXME)

VIRTUAL_WIDGET(ssp5 Tx, 0)
VIRTUAL_WIDGET(ssp1 Rx, 1)
VIRTUAL_WIDGET(ssp1 Tx, 2)
VIRTUAL_WIDGET(DMIC01 Rx, 3)
VIRTUAL_WIDGET(DMic, 4)
VIRTUAL_WIDGET(dmic01_hifi, 5)
VIRTUAL_WIDGET(hif5-0 Output, 6)
VIRTUAL_WIDGET(hif6-0 Output, 7)
VIRTUAL_WIDGET(hif7-0 Output, 8)
VIRTUAL_WIDGET(hifi1, 9)
VIRTUAL_WIDGET(hifi2, 10)
VIRTUAL_WIDGET(hifi3, 11)

VIRTUAL_DAPM_ROUTE_OUT(codec0_out, SSP, 0, OUT, 12)
VIRTUAL_DAPM_ROUTE_OUT(codec1_out, SSP, 0, OUT, 13)
VIRTUAL_DAPM_ROUTE_OUT(ssp1 Tx, SSP, 0, OUT, 14)
VIRTUAL_DAPM_ROUTE_IN(ssp1 Rx, SSP, 0, IN, 15)
VIRTUAL_DAPM_ROUTE_OUT(Capture, SSP, 0, OUT, 16)
VIRTUAL_DAPM_ROUTE_OUT(SoC DMIC, SSP, 0, OUT, 17)
VIRTUAL_DAPM_ROUTE_IN(codec0_in, SSP, 0, IN, 18)





