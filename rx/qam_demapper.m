function [bits_rx, sym_idx] = qam_demapper(symbols, M)
% Convert Gray-coded QAM symbols back to bits.

    k = log2(M);
    assert(floor(k) == k, 'qam_demapper: M must be a power of 2.');

    sym_idx = qamdemod(symbols(:), M, 'gray', 'UnitAveragePower', true);

    bit_matrix = de2bi(sym_idx, k, 'left-msb');

    bits_rx = reshape(bit_matrix.', [], 1);
end
