function y_aligned = align_and_trim(y_full, N_sym, total_delay)
% Select the symbol window after compensating decision delay.
    validateattributes(N_sym, {'numeric'}, {'scalar', 'positive', 'integer', 'finite'});
    validateattributes(total_delay, {'numeric'}, {'scalar', 'nonnegative', 'integer', 'finite'});

    y_full = y_full(:);

    start_idx = total_delay + 1;
    end_idx   = start_idx + N_sym - 1;

    if end_idx > length(y_full)
        error('align_and_trim: Vector length (%d) too short to extract %d symbols at delay %d.', ...
              length(y_full), N_sym, total_delay);
    end

    y_aligned = y_full(start_idx:end_idx);
end
