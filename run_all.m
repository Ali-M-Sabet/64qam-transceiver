function run_all
% Run the main simulation and six experiments in order.
root = fileparts(mfilename('fullpath'));
original_dir = pwd;
original_path = path;
cleanup = onCleanup(@() restore_session(original_dir, original_path));
cd(root);
scripts = {'main.m', 'experiments/exp1_parameter_sensitivity.m', ...
    'experiments/exp2_channel_tracking_study.m', ...
    'experiments/exp3_fixedpoint_wordlength_study.m', ...
    'experiments/exp4_advanced_equalizer_benchmark.m', ...
    'experiments/exp5_mentor_study.m', ...
    'experiments/exp6_step_size_and_ranges.m'};
for index = 1:numel(scripts)
    fprintf('%d/%d: %s\n', index, numel(scripts), scripts{index});
    filename = strrep(fullfile(root, scripts{index}), "'", "''");
    evalin('base', sprintf('run(''%s'');', filename));
end
fprintf('All simulations complete.\n');
end

function restore_session(original_dir, original_path)
cd(original_dir);
path(original_path);
end
