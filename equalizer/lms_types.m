function T = lms_types(dt, W_total, F_override)
% Types table for the floating-point and fixed-point LMS core.

    if nargin < 1 || isempty(dt)
        dt = 'double';
    end
    if nargin < 2 || isempty(W_total)
        W_total = 16;
    end

    switch lower(dt)
        case {'double', 'single'}
            T.r            = complex(cast([], lower(dt)));
            T.s_train      = complex(cast([], lower(dt)));
            T.mu           = cast([], lower(dt));
            T.x            = complex(cast([], lower(dt)));
            T.w            = complex(cast([], lower(dt)));
            T.y_hat        = complex(cast([], lower(dt)));
            T.d            = complex(cast([], lower(dt)));
            T.err          = complex(cast([], lower(dt)));
            T.grad         = complex(cast([], lower(dt)));
            T.update_vec   = complex(cast([], lower(dt)));
            T.w_next       = complex(cast([], lower(dt)));
            T.scale_factor = cast([], lower(dt));
            T.inv_scale    = cast([], lower(dt));

        case 'fxpt'
            fm = fimath('RoundingMethod', 'Nearest', ...
                        'OverflowAction', 'Saturate', ...
                        'ProductMode', 'FullPrecision', ...
                        'SumMode', 'FullPrecision');

            % Integer bits: I = 1 for range [-2.0, +2.0); I = 3 for sqrt(42) in [-8.0, +8.0)
            I_sig1 = 1;
            I_sig0 = 0;
            I_sig3 = 3;

            F_sig1 = max(1, W_total - I_sig1 - 1);
            F_sig0 = max(1, W_total - I_sig0 - 1);
            F_sig3 = max(1, W_total - I_sig3 - 1);

            if nargin >= 3 && isstruct(F_override)
                if isfield(F_override, 'F_x'),      F_x = F_override.F_x;           else, F_x = F_sig1; end
                if isfield(F_override, 'F_w'),      F_w = F_override.F_w;           else, F_w = F_sig1; end
                if isfield(F_override, 'F_y'),      F_y = F_override.F_y;           else, F_y = F_sig1; end
                if isfield(F_override, 'F_d'),      F_d = F_override.F_d;           else, F_d = F_sig1; end
                if isfield(F_override, 'F_e'),      F_e = F_override.F_e;           else, F_e = F_sig1; end
                if isfield(F_override, 'F_mu'),     F_mu = F_override.F_mu;         else, F_mu = F_sig0; end
                if isfield(F_override, 'F_update'), F_update = F_override.F_update; else, F_update = F_sig0; end
            else
                F_x      = F_sig1;
                F_w      = F_sig1;
                F_y      = F_sig1;
                F_d      = F_sig1;
                F_e      = F_sig1;
                F_mu     = F_sig0;
                F_update = F_sig0;
            end

            T.r            = fi(complex(0, 0), 1, I_sig1 + F_x + 1, F_x, fm);
            T.s_train      = fi(complex(0, 0), 1, I_sig1 + F_d + 1, F_d, fm);
            T.mu           = fi(0,             1, I_sig0 + F_mu + 1, F_mu, fm);
            T.x            = fi(complex(0, 0), 1, I_sig1 + F_x + 1, F_x, fm);
            T.w            = fi(complex(0, 0), 1, I_sig1 + F_w + 1, F_w, fm);
            T.y_hat        = fi(complex(0, 0), 1, I_sig1 + F_y + 1, F_y, fm);
            T.d            = fi(complex(0, 0), 1, I_sig1 + F_d + 1, F_d, fm);
            T.err          = fi(complex(0, 0), 1, I_sig1 + F_e + 1, F_e, fm);
            T.grad         = fi(complex(0, 0), 1, I_sig1 + F_x + 1, F_x, fm);
            T.update_vec   = fi(complex(0, 0), 1, I_sig0 + F_update + 1, F_update, fm);
            T.w_next       = fi(complex(0, 0), 1, I_sig1 + F_w + 1, F_w, fm);
            T.scale_factor = fi(0,             1, I_sig3 + F_sig3 + 1, F_sig3, fm);
            T.inv_scale    = fi(0,             1, I_sig0 + F_sig0 + 1, F_sig0, fm);

        otherwise
            error('lms_types: Unknown data type "%s". Use "double", "single", or "FxPt".', dt);
    end
end
