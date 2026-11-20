function bits = generate_bits(N_bits, seed)
% Generate random bits with an optional seed.

validateattributes(N_bits, {'numeric'}, {'scalar', 'positive', 'integer'}, 'generate_bits', 'N_bits');

if nargin >= 2 && ~isempty(seed)
    validateattributes(seed, {'numeric'}, {'scalar', 'nonnegative', 'integer'}, 'generate_bits', 'seed');
    rng(seed, 'twister');
end

bits = randi([0, 1], N_bits, 1);
end
