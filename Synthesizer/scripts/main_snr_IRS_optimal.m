function [radar_heatmap, visible_cart_v] = main_snr_IRS_optimal
    % Copyright (c) 2018-2020 Junfeng Guan, Sohrab Madani, Suraj Jog, Saurabh Gupta, 
    % Haitham Hassanieh, University of Illinois at Urbana-Champaign
    % 
    % Permission is hereby granted, free of charge, to any person obtaining a copy
    % of this software and associated documentation files (the "Software"), to deal
    % in the Software without restriction, including without limitation the rights
    % to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    % copies of the Software, and to permit persons to whom the Software is
    % furnished to do so, subject to the following conditions:
    % 
    % The above copyright notice and this permission notice shall be included in
    % all copies or substantial portions of the Software.
    % 
    % THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    % IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    % FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    % AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    % LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    % OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
    % THE SOFTWARE.

    close all; clear; clc;
    addpath('functions');

    variable_library;
    variable_library_radar;
    %Import an STL mesh, returning a PATCH-compatible face-vertex structure
    % fv = stlread('../../w.stl');
    nTx = 4;    
    % points = fv.Points;
    % [points_size, cdd] = size(points);
    
    
    c1=1;
    c2=2;
    ux=0;
    uy=0;
    uz=1;
    sx=0;
    sy=0;
    sz=0;
    ax=0;
    ay=0;
    az=1;
    
    pointsTotal = [0,0,0];
    
    
    for x=1:10
        for z=1:20
            point=[0.1*x-0.5,-0.50,z*0.1];
            pointsTotal = [pointsTotal; point];
        end
    end

    
    for x=1:10
        for z=1:20
            point=[0.1*x-0.5,0.50,z*0.1];
            pointsTotal = [pointsTotal; point];
        end
    end

    for y=1:10
        for z=1:20
            point=[-0.40,0.1*y-0.6,z*0.1];
            pointsTotal = [pointsTotal; point];
        end
    end
  
    for y=1:10
        for z=1:20
            point=[0.50,0.1*y-0.5,z*0.1];
            pointsTotal = [pointsTotal; point];
        end
    end
    ptCloud = pointCloud(pointsTotal(2:801, :));
    %ptCloud = pointCloud(pointsTotal);
    ptCloudO = ptCloud;
    
    


     directory_path = './Sim_Walking';
     txt_files = dir(fullfile(directory_path, '*.txt'))
     
     for p = 1:numel(txt_files)
        % Get the filename
        file_name = txt_files(p).name;
        
        % Extract the first num_chars characters
        range = str2double(file_name(1:2));
        users = file_name(12);
        modal = file_name(6:11);
        
    X_Coord = [linspace(-range/2, range/2,100); linspace(-range/2, range/2,100); linspace(-range/2, -range/2,100); linspace(range/2, range/2,100)];
     Y_Coord = [linspace(0 ,0,100); linspace(range ,range,100);linspace(0 ,range,100); linspace(0 ,range,100)];
    Z_Coord = linspace(0,2,10); 
        
     
     new_folder=['../results/SNR/','Optimal', '-Pow', num2str(Tx_power),'dB-Range', num2str(range), 'm-Users', num2str(users), '-', modal];
     mkdir( new_folder);  
     %fileID = fopen([new_folder,'/Transformations.txt'],"w");
     % 
    % Perform Delaunay triangulation
    % load('../../CAD_model_1.mat');
    % 
    % pcshow(cart_v);
    % title('STL Occluded Point Cloud');
    fid = fopen((['./Sim_Walking/', file_name]), 'r');
    users=str2double(users);
    x_coordinates = cell(users,600);
    y_coordinates = cell(users, 600);

    x_data = zeros(users,600);
    y_data = zeros(users, 600);

    transf = cell(users, 2);

 for U = 1:users
    line = fgetl(fid);
    
    % Extract data within curly braces
    data_str = extractBetween(line, '{', '}');
    
    % Split data into individual coordinate sets
    coordinates = extractBetween(data_str{1}, '[', ']');
    
    % Process each coordinate set
    x_coordinates(U,:) =  split(coordinates(1), ',');
    y_coordinates(U,:) =  split(coordinates(2), ',');
    
    x_data(U,:) = cellfun(@str2double, x_coordinates(U,:));
    y_data(U,:) = cellfun(@str2double, y_coordinates(U,:));
    

 end

 SNR_output = ones(600,4*users);  
 SD_output = ones(600,4*users);  
 finalSNR= ones(600,4,users);
 finalSD= ones(600,4,users);
 positions = ones(600,4,users,3)


 X_Coord = [linspace(-range/2, range/2,50); linspace(-range/2, range/2,50); linspace(-range/2, -range/2,50); linspace(range/2, range/2,50)];
 Y_Coord = [linspace(0 ,0,50); linspace(range ,range,50);linspace(0 ,range,50); linspace(0 ,range,50)];
 Z_Coord = linspace(0,2,6); 

    for CAD_idx = 1:600
         close all;
       
    
       for U = 1:users

        translationx =x_data(U,CAD_idx);
        translationy = y_data(U,CAD_idx) + range/2; 

        ux=translationx;
        uy=translationy;
        
        transf(U,:)={translationx, translationy};
            
               
        rotationAngles = [0 0 0];
        tform = rigidtform3d(rotationAngles,[translationx translationy 0]);
        
        if(U>1)
             if(U==2)
                ptCloud2 = pctransform(ptCloudO,tform);
                mergedPoints = [ptCloud.Location; ptCloud2.Location];

                % Create a new point cloud from the merged points
                ptCloud = pointCloud(mergedPoints);
             else
                ptCloud3 = pctransform(ptCloudO,tform);
                mergedPoints = [ptCloud.Location; ptCloud3.Location];

                % Create a new point cloud from the merged points
                ptCloud = pointCloud(mergedPoints);
             end
        else
            ptCloud = pctransform(ptCloudO,tform);
        end
         
         
       end
         
       
        % load the surface model
        
        % 
        % CAD models are loaded as point clouds of size N_pt by 3, where N_pt
        % is the number of points and 3 values are the cartesian coordinates
        % unit is mm
        
        % Visulize the original point cloud
%         figure; 
%         cart_v_plot = cart_v;
% %         cart_v_plot = datasample(cart_v, 1000); % downsampling when plotting
%         scatter3(cart_v_plot(:,1),cart_v_plot(:,2),cart_v_plot(:,3),10,'filled','k'); hold on;
%         xlabel('x (mm)'); ylabel('y (mm)'); zlabel('z (mm)'); axis equal;
%         set(gca,'FontSize',30) % Creates an axes and sets its FontSize to 18
        
        %store point cloud in pc (point cloud) structure
        car_v = car_v_struct;
        car_v.CAD_idx = CAD_idx;
        car_v.N_pt = length(ptCloud.Location);
        car_v.cart_v = ptCloud.Location;
       % car_v.lim = [min(ptCloud.Location);max(ptCloud.Location)]; % find the limits in all three dimensions 
       % [bbox_x, bbox_y, bbox_z] = meshgrid(car_v.lim(:,1),car_v.lim(:,2),car_v.lim(:,3)); % 8 vertices of the bounding box of the point cloud
        %car_v.bbox = [bbox_x(:), bbox_y(:), bbox_z(:)]; 
        %clear cart_v bbox N_pt car_idx;
        car1_v_origin = car_v;
        % car_v = car_v_struct;
        % car_v.CAD_idx = CAD_idx;
        % car_v.N_pt = length(cart_v);
        % car_v.cart_v = cart_v;
        % car_v.lim = [min(cart_v);max(cart_v)]; % find the limits in all three dimensions 
        % [bbox_x, bbox_y, bbox_z] = meshgrid(car_v.lim(:,1),car_v.lim(:,2),car_v.lim(:,3)); % 8 vertices of the bounding box of the point cloud
        % car_v.bbox = [bbox_x(:), bbox_y(:), bbox_z(:)]; 
        % clear cart_v bbox N_pt car_idx;
        % car1_v_origin = car_v;
         
       SD_stored = ones(users,4,100,10); 
       SNR_stored = ones(users,4,100,10);
      
       maximSNR = ones(4,users);
       min_index = ones(4,users,2);
       


       [x,y,z,ind]=GradientAscent(range,1, 8, ax, ay, az, ux, uy, 1, sx, sy, sz, 0.001, 1000000, 0.001)
            location = [x,y,z];
            SNR_obtain = SNRRand(users, ind, ptCloud.Location, location);

            i=0;
            k=0;
            SNR_obtainn=zeros(users);
            while (i<length(SNR_obtain))
                                SNR_subset = SNR_obtain((1+200*k):200*(k+1) );
                                SNR_subset_mean = mean(SNR_subset);
                                SNR_subset_std = std(SNR_subset);
                                SNR_obtainn(k+1) = SNR_subset_mean;
                                SNR_output(CAD_idx,ind+4*k) = SNR_subset_mean;
                                SD_output(CAD_idx,ind+4*k) = SNR_subset_std;
                                i=i+200;
                                k=k+1;
            end
                for Tx=1:nTx
                    
                    if(ind~=Tx)
                        Similar=zeros(users,1);
                        SimilarSD=zeros(users,1)
                        obtained=zeros(users,1);
                        
                        for xy=1:50
                            for z=1:6
                            if any(obtained~=1)
                            location = [X_Coord(Tx,xy),Y_Coord(Tx,xy),Z_Coord(z)];
                            SNR = SNRRand(users, Tx, ptCloud.Location, location);
                            
        
                            i=0;
                            k=0;
                           
                            while (i<length(SNR))
                                SNR_subset = SNR((1+200*k):200*(k+1) );
                                SNR_subset_mean = mean(SNR_subset);
                                SNR_subset_std = std(SNR_subset);

                                if(SNR_subset_mean<SNR_obtainn(k+1)*(1.0075) && SNR_subset_mean>SNR_obtainn(k+1)*(0.9925)&& obtained(k+1)~=1)
                                   obtained(k+1) = 1;
                                   SNR_output(CAD_idx,Tx+4*k) = SNR_subset_mean;
                                   SD_output(CAD_idx,Tx+4*k) = SNR_subset_std;
                                end
                                
                                if(abs(SNR_obtainn(k+1)-Similar(k+1)) > abs(SNR_obtainn(k+1)-SNR_subset_mean))
                                    Similar(k+1)=SNR_subset_mean;
                                    SimilarSD(k+1)=SNR_subset_std;
                                end

                                i=i+200;
                                k=k+1;
                            end
                            
                            if (xy==50 && z==6)
                                indic = find(obtained==0);
                                    for o=1:length(indic)
                                    c=indic(o)
                                    SNR_output(CAD_idx,Tx+4*(c-1)) = Similar(c);
                                    SD_output(CAD_idx,Tx+4*(c-1)) = SimilarSD(c);
                                    
                                    end
                            end
                            
                            end
                        end
                    end
                end

                

             


            
                
        
    end
    save(['../results/',new_folder,'/','SNR.mat'], 'SNR_output');
    save(['../results/',new_folder,'/','SD.mat'], 'SD_output');
    end
end