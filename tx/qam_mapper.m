function [symbols, constellation] = qam_mapper(bits, M)
% Map bits to unit-average-power, Gray-coded QAM.

bits = bits(:);
k = log2(M);
assert(floor(k) == k, 'qam_mapper: M must be a power of 2.');
assert(mod(numel(bits), k) == 0, 'qam_mapper: Bit length must be divisible by k = %d.', k);

N_sym = numel(bits) / k;

bit_matrix  = reshape(bits(:), k, N_sym).';
sym_indices = bi2de(bit_matrix, 'left-msb');

symbols = qammod(sym_indices, M, 'gray', 'UnitAveragePower', true);

if nargout > 1
    constellation = qammod((0:M-1).', M, 'gray', 'UnitAveragePower', true);
end
end
