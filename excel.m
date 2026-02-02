%% 智能手机续航预测模型验证可视化
% 定义颜色方案
color_pred = [0.2, 0.4, 0.8];    % 预测值 - 蓝色
color_actual = [0.8, 0.4, 0.2];   % 实际值 - 橙色
color_error = [0.6, 0.4, 0.9];   % 误差 - 紫色

%% 输入验证数据
% 机型列表
models = {'iPhone 14 Pro Max', 'iPhone 15 Pro', 'iPhone 15 Pro Max', ...
          'Galaxy S24 Ultra', 'Galaxy S23 Ultra', 'Pixel 8 Pro'};
      
% 场景列表
scenarios = {'Idle min', 'WiFi Web 150nits', 'H.264 1080p', 'Load max'};

% 预测续航时间 (小时)
predicted_hours = [
    57.88, 17.25, 30.34, 6.57;     % iPhone 14 Pro Max
    45.23, 13.23, 23.42, 5.02;     % iPhone 15 Pro
    58.57, 17.61, 30.89, 6.73;     % iPhone 15 Pro Max
    37.12, 16.07, 24.67, 6.95;     % Galaxy S24 Ultra
    35.65, 15.79, 24.02, 6.90;     % Galaxy S23 Ultra
    22.40, 12.57, 17.21, 6.24      % Pixel 8 Pro
];

% 实际续航时间 (小时)
actual_hours = [
    57.88, 15.80, 28.10, 6.93;     % iPhone 14 Pro Max
    45.23, 13.87, 25.37, 6.03;     % iPhone 15 Pro
    58.57, 19.38, 33.55, 6.40;     % iPhone 15 Pro Max
    37.12, 19.13, 32.03, 3.37;     % Galaxy S24 Ultra
    35.65, 18.33, 25.72, 6.67;     % Galaxy S23 Ultra
    22.40, 12.67, 18.70, 3.67      % Pixel 8 Pro
];

% 相对误差 (%)
relative_error = [
    0.0, +9.2, +8.0, -5.1;           % iPhone 14 Pro Max
    0.0, -4.6, -7.7, -16.8;        % iPhone 15 Pro
    0.0, -9.1, -7.9, +5.1;          % iPhone 15 Pro Max
    0.0, -16.0, -23.0, +106.6;      % Galaxy S24 Ultra
    0.0, -13.9, -6.6, +3.5;         % Galaxy S23 Ultra
    0.0, -0.8, -8.0, +70.1          % Pixel 8 Pro
];

%% 创建图形窗口
figure('Position', [100, 100, 1400, 900], 'Color', 'white');


%% Subplot 2: Relative Error Heatmap (Revised Version)
subplot(2, 3, 2);
% Create heatmap of relative errors - includes all four scenarios
imagesc(relative_error'); % Transpose matrix so rows correspond to scenarios, columns to phone models

% Set axis labels
set(gca, 'YTick', 1:length(scenarios), 'YTickLabel', scenarios);
set(gca, 'XTick', 1:length(models), 'XTickLabel', models, 'XTickLabelRotation', 45);
xlabel('Smartphone Models', 'FontSize', 10, 'FontWeight', 'bold');
ylabel('Usage Scenarios', 'FontSize', 10, 'FontWeight', 'bold');
title('Relative Error Heatmap by Scenario and Model (%)', 'FontSize', 11, 'FontWeight', 'bold');

% Add colorbar and set red-blue colormap
c = colorbar;
colormap(redbluecmap); % Red-blue colormap: red indicates positive error, blue indicates negative error
ylabel(c, 'Relative Error (%)', 'FontSize', 9, 'FontWeight', 'bold');

% 添加误差数值标签 - 已修改为正数前加正号
for i = 1:size(relative_error, 2) % 遍历所有场景（列）
    for j = 1:size(relative_error, 1) % 遍历所有机型（行）
      
            textColor = 'white';
        
        
        % 根据误差值选择显示格式
        if relative_error(j, i) > 0
            % 正数前添加正号
            format_str = '%+.1f%%';
        else
            % 负数或零保持原样
            format_str = '%.1f%%';
        end
        
        text(j, i, sprintf(format_str, relative_error(j, i)), ...
            'HorizontalAlignment', 'center', 'FontSize', 7, 'FontWeight', 'bold', ...
            'Color', textColor);
    end
end

% Optimize layout
axis tight;