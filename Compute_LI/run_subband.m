function run_subband(IDs,N_sa, N_modes,d_out, WhichSignals, dir_save, modes_dir, d_utils)
    
    d_sgwt = fullfile(d_utils, 'sgwt_toolbox');
    d_spg  = fullfile(d_utils, 'spg_v1.01');

    addpath(genpath(d_sgwt));
    addpath(d_utils);
    addpath(d_spg);
    
    n_eigs.lh = 'white-lh_norma_eval_2000.txt';
    n_beta.lh='lh_betas_all_mode_2000_normed.mat';
    n_eigs.rh = 'white-rh_norma_eval_2000.txt';
    n_beta.rh ='rh_betas_all_mode_2000_normed.mat';
    hemis = {'lh', 'rh'};
    
    [A_v1, B_v1, A_v2, B_v2] = load_and_process_data(IDs, N_modes,WhichSignals, d_out, hemis, n_eigs, n_beta, modes_dir);

    %-Energy equalizing warping. 
    disp("Energy equalizing wrapping");
    [w_v1, e_v1, w_ns_v1] = hb_get_consensus_ee_warping(A_v1, B_v1); 
    [w_v2, e_v2, w_ns_v2] = hb_get_consensus_ee_warping(A_v2, B_v2);
    
    e = e_v1;
    lmax = e(end);
    disp(sprintf("max lambda : %s",  lmax));
    
    save(fullfile(dir_save, 'lmax.mat'),'lmax');
    
    %-saSOSKS.
    
    g_v1 = spgg_filter_design(lmax, N_sa,...
    'designtype', 'signal_adapted', ...
    'warping', w_v1, ...
    'E', e); 
    g_v2 = spgg_filter_design(lmax, N_sa,...
    'designtype', 'signal_adapted', ...
    'warping', w_v2, ...
    'E', e); 

    assign_and_save_modes(A_v1, g_v1, lmax, IDs,d_out, modes_dir, false) ;
    assign_and_save_modes(A_v2, g_v2, lmax, IDs,d_out, modes_dir, true) ;
    
    disp("PLOTTING");
    plot_wrapping(e,lmax,w_ns_v1, w_v1,w_ns_v2,w_v2,dir_save);
    plot_saSOKS(g_v1, g_v2,lmax, dir_save);
    disp("DONE"); 
    
end 
%==========================================================================
function [A_v1, B_v1, A_v2, B_v2] = load_and_process_data(IDs, N_modes,WhichSignals, d_out, hemis, n_eigs, n_beta, modes_dir)

    Ns = length(IDs);

    A_v1 = cell(2*Ns,1);
    A_v2 = cell(Ns,2);
    B_v1 = cell(2*Ns,1);
    B_v2 = cell(Ns,2);

    % compute cumsum if not given based on given set of eigs (A) & energies (B)
    % A: Nx1 cell array; each cell a vector of eigenvalues starting from 0.
    % B: Nx1 cell array; each cell a matrix of energies, one signal per column.
    % - If length of A{k} is L then B{k} is a LxM matrix where M >=1.
    % - Length of vectors in A may differ.
    % - First and second dimension of matrices in B may differ.

    for iID=1:Ns

        ID = IDs(iID);
        disp(sprintf("Process Subject - %s",  num2str(ID)));
        d_mat = fullfile(d_out, num2str(ID), modes_dir);
        d_txt = fullfile(d_out, num2str(ID), modes_dir);
        e1 = ~exist(d_mat, 'dir');
        e2 = ~exist(d_txt, 'dir');
        if  or(e1,e2)
            continue;
        end

        iABv1 = (iID-1)*2+1;
        for iH = 1:2
            
            hemi = hemis{iH};
            f_eigs = fullfile(d_txt, n_eigs.(hemi));
            f_betas=fullfile(d_mat, n_beta.(hemi));
            E = loadeigs(f_eigs, N_modes); % eigs
            
            betas = load(f_betas);  %beta
            betas=betas.recon_beta_final;
            betas=select_signals(betas,WhichSignals); 

            [N,P] = size(betas);
            power_spectrum = abs(betas).^2;
            F = power_spectrum./repmat(nansum(power_spectrum,1), N, 1);

            switch hemi
                case 'lh'
                    A_v1{iABv1,1} = E(:);
                    B_v1{iABv1,1} = F;
                    A_v2{iID,  1} = E(:);
                    B_v2{iID,  1} = F;
                case 'rh'
                    A_v1{iABv1+1,1} = E(:);
                    B_v1{iABv1+1,1} = F;
                    A_v2{iID,    2} = E(:);
                    B_v2{iID,    2} = F;
            end
        end
    end
end 

function S = select_signals(S_raw, WhichSignals)
    if ischar(WhichSignals)
        d = size(S_raw, 2);
        switch WhichSignals
            case 'all'
                idx= 1:size(S_raw,2); % 100%
            case 'rh' 
                idx=201:400;
            case 'lh'
                idx=1:200;
            case 'rand-80'
                idx = randperm(d, 80); % 20%
            case 'rand-40'
                idx = randperm(d, 40); % 10%
            case 'rand-20'
                idx = randperm(d, 20); % 5%
            otherwise
                error('Invalid option for WhichSignals.');
        end
        S = S_raw(:, idx);
    elseif isnumeric(WhichSignals)
        S = S_raw(:, WhichSignals);
    else
        S = S_raw;
    end
end

%==========================================================================
function assign_and_save_modes(A_v1, g_v1, lmax, IDs, d_out, modes_dir,diff_)

    for i = 1:(size(A_v1, 1))
        [Y1, Y2, UnAssigned] = mode2band(g_v1, A_v1{i}, lmax);
    % Determine subject ID and hemisphere based on index i
        if mod(i, 2) == 1
            subject_id = IDs((i+1)/2);  % Odd index corresponds to lh
            hemisphere = 'lh';
        else
            subject_id = IDs(i/2);      % Even index corresponds to rh
            hemisphere = 'rh';
        end
        
        % Define the directory to save MAT files
        save_dir = fullfile(d_out, num2str(subject_id), modes_dir);
        if(diff_)
            Y1_filename = fullfile(save_dir, sprintf('%s_grouped_indexes_diff.mat', hemisphere));
            Y2_filename = fullfile(save_dir, sprintf('%s_grouped_values_diff.mat', hemisphere));
            UnAssigned_filename = fullfile(save_dir, sprintf('%s_unsassigned.mat', hemisphere));

        else 
            Y1_filename = fullfile(save_dir, sprintf('%s_grouped_indexes_basic.mat', hemisphere));
            Y2_filename = fullfile(save_dir, sprintf('%s_grouped_values_basic.mat', hemisphere));
            UnAssigned_filename = fullfile(save_dir, sprintf('%s_unsassigned_basic.mat', hemisphere));
        end 
        
        save(Y1_filename,'Y1'); 
        save(Y2_filename,'Y2'); 
        save(UnAssigned_filename,'UnAssigned'); 
    end

end 

%==========================================================================
%-Plots.
%==========================================================================
function plot_wrapping(e,lmax,w_ns_v1, w_v1,w_ns_v2,w_v2,dir_save)
    hf1 = figure(1);
    set(hf1,'position',[1 330 1000 200]);
    hold on;
    plot(e,e/lmax,'r:','displayname','no warping');
    plot(e,w_ns_v1,'m','displayname','non-smoothed warping v1');
    plot(e,w_v1,'k','displayname','smoothed warping v1');
    plot(e,w_ns_v2,'m','displayname','non-smoothed warping v2');
    plot(e,w_v2,'k','displayname','smoothed warping v2');
    xlabel('\lambda');
    ylabel('warping');
    xlim([0 lmax])
    ylim([0 1.05])
    legend('location','nw');
    grid on
    box off
    saveas(hf1,sprintf('%s/wraping_function.png',dir_save));
end 
%==========================================================================
function plot_saSOKS(g_v1, g_v2,lmax, dir_save)
    hf2 = figure(2);
    set(hf2,'position',[1 50 1100 800]);

    subplot(211);
    ttl1 = 'based on difference in signal energy bw lh & rh';
    plotg(g_v2, lmax, ttl1)

    subplot(212);
    ttl2 = 'based on average signal energy across both lh & rh';
    plotg(g_v1, lmax, ttl2);
    x_mm = xlim;
   
    saveas(hf2,sprintf('%s/saSOSKS_indiv.fig',dir_save));
    saveas(hf2,sprintf('%s/saSOSKS_indiv.png',dir_save));

end 
%==========================================================================
function indiv_dis(UnAssigned,e, Y1,  dir_save, x_mm)
    hf3 = figure(1);
    x = e;   
    y = Y1;
    x(UnAssigned) = [];
    y(UnAssigned) = [];
    scatter(x, y, 3, 'k', 'filled', DisplayName='Assigned Modes');
    hold on;
    scatter(e(UnAssigned), zeros(size(UnAssigned)), 5, 'r', 'filled',  DisplayName='Unassigned Mode');
    legend('Location', 'se');
    xlabel('volume corrected \lambda');
    ylabel('subband index');
    title("Repartition");
    grid on;
    xlim(x_mm)
    set(gca, 'FontSize',16);
    saveas(hf3,sprintf('%s/saSOSKS_indiv.png',d_hcp));
   
    
end 
%==========================================================================
function E = loadeigs(f,N)
fid = fopen(f, 'r');
[E,count] = fscanf(fid, '%f');
assert(count==N);
fclose(fid);
end

%==========================================================================
function plotg(g,lmax,ttl)
s = 1e5; % if small, for large N_sa, lower-end kernels will appear jagged
e = linspace(0,lmax,s);
N = length(g);
axis;
hold on;
for k=1:N
    plot(e,g{k}(e));
end
xlabel('volume-corrected \lambda');
ylabel('amplitude');
xlim([0 lmax])
ylim([0 1.05])
grid on
box off
title(ttl);
set(gca, 'FontSize', 16);
end

%==========================================================================
function [Y1, Y2, UnAssigned] = mode2band(g, A, lmax)
UnAssigned = find((A>lmax));
N_ua = length(UnAssigned);
A(UnAssigned) = [];
N = size(A,1);
J = length(g);
G = zeros(N,J);

for j=1:J
    G(:,j) = g{j}(A(:)');
    
end
[~, Y1] = max(G,[],2);
Y1 = [Y1(:); zeros(N_ua,1)];
Y2 = cell(J,1);
for j=1:J
    
    Y2{j} = find(Y1==j);
end
assert(isequal(sort(UnAssigned), find(Y1==0)));
end
