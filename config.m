% Simulation settings and source paths.
projectRoot = fileparts(mfilename('fullpath'));
if ~isempty(projectRoot)
    addpath(projectRoot);
    sourceFolders = {'channel', 'equalizer', 'experiments', 'metrics', ...
                     'plots', 'rx', 'tx'};
    for pathIndex = 1:numel(sourceFolders)
        addpath(fullfile(projectRoot, sourceFolders{pathIndex}));
    end
end

RNG_SEED = 42;
rng(RNG_SEED, 'twister');

M = 64;
k = log2(M);                     % 6 bits/symbol

N_SYM  = 200000;                  % Number of symbols
N_BITS = N_SYM * k;               % Total bits (1.2e6)

SNR_EbN0_dB = 10:2:30;            % Eb/N0 sweep range in dB (10 to 30 dB per spec)
SNR_REF_DB  = 22;                 % Representative operating point for EVM & constellation audits

h_raw  = [1.0, 0.45, 0.2];
H_ISI  = h_raw / norm(h_raw);     % Unit-energy normalization

h_tv_step_raw = [1.0, 0.37, 0.24];
H_TV_STEP     = h_tv_step_raw / norm(h_tv_step_raw);
H_TV_DRIFT    = H_TV_STEP;

EQ_LEN   = 9;                     % Filter taps
EQ_DELAY = 4;                     % Center decision delay

LMS_N_EQ    = 9;
LMS_DELAY   = 4;
LMS_MU      = 0.0200;             % Step size
LMS_N_TRAIN = 300;                % Pilot training symbols
NLMS_MU     = 0.18;               % Normalized LMS step size
NLMS_EPS    = 1e-6;               % Regularization constant

FXPT_W_PRIMARY = 16;              % Q(1.14)
FXPT_W_REDUCED = 12;              % Q(1.10)

EXPORT_FIGS = false;
FIG_RES     = 150;
REPORT_DIR  = fullfile(projectRoot, 'results', 'figures');
