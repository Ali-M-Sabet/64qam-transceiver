function evm_pct = compute_evm(symbols_ref, symbols_rx)
% RMS EVM relative to the reference symbol power.

    symbols_ref = symbols_ref(:);
    symbols_rx  = symbols_rx(:);

    assert(~isempty(symbols_ref) && numel(symbols_ref) == numel(symbols_rx), ...
        'compute_evm:SizeMismatch', 'Symbol streams must be nonempty and equally sized.');

    error_vec   = symbols_rx - symbols_ref;
    ref_power   = mean(abs(symbols_ref).^2);
    assert(ref_power > 0, 'compute_evm:ZeroReference', 'Reference power must be positive.');
    error_power = mean(abs(error_vec).^2);

    evm_pct = 100 * sqrt(error_power / ref_power);
end
