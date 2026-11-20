# 64-QAM Transceiver with Adaptive Equalization

A MATLAB project that sends Gray-coded 64-QAM symbols through noise and multipath, recovers them with fixed and adaptive equalizers, and studies the precision needed for fixed-point LMS. Developed during the Analog Devices summer internship.

## What the project does

```text
Random bits -> 64-QAM mapper -> Multipath channel + noise
                                        |
                                  Equalizer
                                        |
                             QAM demapper -> Recovered bits
                                        |
                                BER, SER, EVM, MSE
```

The main simulation establishes the link and compares ZF, MMSE, and LMS. Six experiments then study filter length, channel tracking, word length, NLMS, mixed precision, step size, and register ranges.

The nominal channel is `[1, 0.45, 0.2]`, normalized to unit energy. The adaptive equalizer uses nine taps, decision delay four, and 300 known training symbols. It then switches to decision-directed operation, using its detected symbols to continue adapting.

## Main results

At 22 dB Eb/N0, the main sweep measures:

| Receiver | EVM |
| --- | ---: |
| AWGN baseline | 3.24% |
| Multipath before equalization | 45.48% |
| LS-ZF | 4.05% |
| MMSE | 4.05% |
| LMS | 4.32% |

The word-length study measures 4.35%, 4.46%, and 5.83% EVM for 16-, 14-, and 12-bit main registers. These results identify useful precision choices and show the recovery boundary at narrower widths.

A separate mixed-precision model combines a 12-bit datapath with a 16-bit internal coefficient/update path and measures 4.35% EVM. The three-seed step-size study supports the default `mu = 0.02` for the tested configuration.

The [technical report](report/ADI_64QAM_Technical_Report.pdf) presents the detailed measurements, analysis, and 24 plots.

## Run

Tested with MATLAB R2026a Update 4, Communications Toolbox, Signal Processing Toolbox, and Fixed-Point Designer.

Open MATLAB in this folder and run:

```matlab
run_all
```

This runs the main simulation and all six experiments in order. Each script displays its figures in MATLAB. The fixed-point studies take most of the runtime.

Generated measurements are written to the Git-ignored `results/` folder. Experiment 3 saves `wordlength_results.mat`, which Experiment 5 reads to select the datapath width. Experiment 6 saves its MAT data and two CSV tables for convenient inspection after a run.

Figure export is off by default. To save PNGs as well, set `EXPORT_FIGS = true` in `config.m`; they will be written to `results/figures/`.

To run one simulation:

```matlab
main
run('experiments/exp1_parameter_sensitivity.m')
```

Run Experiment 3 before Experiment 5 when refreshing the word-length data used for width selection.

## Code guide

| Section | Files and purpose |
| --- | --- |
| Settings and execution | [config.m](config.m) sets parameters and source paths. [main.m](main.m) runs the baseline link. [run_all.m](run_all.m) runs the complete workflow in order. |
| [tx/](tx/) | `generate_bits.m` creates the data; `qam_mapper.m` maps six bits to each normalized 64-QAM symbol. |
| [channel/](channel/) | `add_awgn.m` adds complex noise; `apply_fir_channel.m` applies fixed multipath; `time_varying_channel.m` applies a channel step or drift. |
| [rx/](rx/) | `align_and_trim.m` compensates decision delay; `qam_demapper.m` recovers the bits. |
| [equalizer/](equalizer/) | `design_zf_equalizer.m` and `design_mmse_equalizer.m` calculate fixed coefficients; `apply_fir_equalizer.m` applies them. `lms_core.m` and `nlms_equalizer.m` update coefficients sample by sample. `lms_types.m` sets numeric formats; `log_quantization.m` measures register casts. |
| [metrics/](metrics/) | `compute_ber_ser.m` counts bit/symbol errors; `compute_evm.m` measures constellation error; `compute_mse.m` measures mean squared error. |
| [plots/](plots/) | Eight helpers draw and export the constellation, BER, channel, equalizer, learning, tracking, and sensitivity figures. |

## Experiments

| File | Study | Figures |
| --- | --- | --- |
| [main.m](main.m) | Loopback, AWGN versus theory, multipath, fixed/adaptive equalizers, tracking, and float/fixed comparison | 01-08 |
| [exp1_parameter_sensitivity.m](experiments/exp1_parameter_sensitivity.m) | MMSE over three seeds, fixed-filter tap count, and channel-estimate perturbations | 09-10 |
| [exp2_channel_tracking_study.m](experiments/exp2_channel_tracking_study.m) | Frozen MMSE and adaptive LMS during a channel step and drift | 11-13 |
| [exp3_fixedpoint_wordlength_study.m](experiments/exp3_fixedpoint_wordlength_study.m) | Float64 and 16/14/12/10/8-bit LMS registers, measured with BER, EVM, and SQNR | 14-16 |
| [exp4_advanced_equalizer_benchmark.m](experiments/exp4_advanced_equalizer_benchmark.m) | ZF/MMSE/LMS/NLMS comparison, a +12 dB input amplitude step, and coefficient leakage | 17-18 |
| [exp5_mentor_study.m](experiments/exp5_mentor_study.m) | Noise-free channels, low-SNR tap count, training/DD handoff, width selection, and mixed precision | 19-23 |
| [exp6_step_size_and_ranges.m](experiments/exp6_step_size_and_ranges.m) | Three-seed step-size comparison and pre/post-cast ranges with saturation counts at 13 boundaries | 24 |

## Model and measurements

This is a symbol-spaced complex-baseband model with unit average symbol energy. Adaptive payload measurements exclude the first 300 training symbols. BER entries report errors observed in the tested packets.

The types-table core uses nearest rounding, saturating register casts, and full-precision intermediate products/sums. The separate mixed-precision experiment uses its own cast locations. The report's 43.75% width-squared estimate compares 12-by-12 with 16-by-16 products.

Experiment 1's MMSE comparison and Experiment 6's step-size comparison each use three seeds. Experiment 5's low-SNR tap sweep uses one seed. A multi-seed version of that tap sweep and a combined baseline-versus-selected-design comparison are separate extensions.

## Report

The [technical report](report/ADI_64QAM_Technical_Report.pdf) is included as a PDF.
