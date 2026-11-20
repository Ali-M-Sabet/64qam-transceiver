function [BER, SER] = compute_ber_ser(bits_tx, bits_rx, k)
% Measure bit and symbol errors for equal-length streams.

    bits_tx = bits_tx(:);
    bits_rx = bits_rx(:);

    assert(~isempty(bits_tx) && numel(bits_tx) == numel(bits_rx), ...
        'compute_ber_ser:SizeMismatch', 'Bit streams must be nonempty and equally sized.');
    N = numel(bits_tx);

    assert(mod(N, k) == 0, 'compute_ber_ser: Bit count (%d) must be multiple of k = %d.', N, k);

    bit_errors = sum(bits_tx ~= bits_rx);
    BER = bit_errors / N;

    N_sym  = N / k;
    sym_tx = reshape(bits_tx, k, N_sym).';
    sym_rx = reshape(bits_rx, k, N_sym).';

    sym_errors = sum(any(sym_tx ~= sym_rx, 2));
    SER = sym_errors / N_sym;
end
