function row = log_quantization(row, input, stored, prototype)
% Accumulate pre/post-cast ranges and low/high saturation counts.
% Columns: input min/max, stored min/max, components, low clips, high clips.
values = double(input(:));
outputs = double(stored(:));
if ~isreal(input) || ~isreal(stored)
    values = [real(values); imag(values)];
    outputs = [real(outputs); imag(outputs)];
end
row(1) = min(row(1), min(values));
row(2) = max(row(2), max(values));
row(3) = min(row(3), min(outputs));
row(4) = max(row(4), max(outputs));
row(5) = row(5) + numel(values);
if isfi(prototype)
    nt = numerictype(prototype);
    assert(strcmp(nt.Signedness, 'Signed') && strcmp(prototype.RoundingMethod, 'Nearest') && ...
        strcmp(prototype.OverflowAction, 'Saturate'), ...
        'log_quantization expects a signed format with nearest rounding and saturation.');
    rounded = floor(values * 2^prototype.FractionLength + 0.5);
    limit = 2^(prototype.WordLength - 1);
    row(6) = row(6) + nnz(rounded < -limit);
    row(7) = row(7) + nnz(rounded > limit - 1);
end
end
