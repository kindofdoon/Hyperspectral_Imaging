function hyperspectral_image_GUI
    
    % A spectral imaging GUI. Creates hyperspectral datacubes from photos
    % gathered by spectral scanning through bandpass filters. Supports
    % multiple filters, cameras, observers. Supports custom sampling of
    % SPDs and reflectance spectra, and performs image reconstruction.
    
    % Daniel W. Dichter
    % 2021-08-12
    % daniel.w.dichter@gmail.com
    
    %%

    clc
    
    %% Declare globals
    
    Wavelength = [];
    Observer   = [];
    Photo      = [];
    Filter     = [];
    Image      = [];
    Camera     = [];
    Sensor     = [];
    HSDC        = [];
    
    %% GUI properties
    
    GUI.fig_size_basic = round([560 420] .* 1); % px
    GUI.input_dims     = [175 25]; % px, size of dropdowns, sliders, buttons, etc.
    GUI.input_x        = 170; % px
    GUI.label_x        = 20; % px
    GUI.col_bac        = zeros(1,3) + 0.90; % background color for buttons, dropdowns, etc.
    GUI.col_hi         = [180 255 180]./255; % highlight color
    GUI.fs             = 10; % fontsize
    GUI.gap_small      = 1; % px
    GUI.gap_large      = 15; % px
    GUI.label_off_vert = 4; % px, label offset, vertical
    
    % Default sizes for all figures
    GUI.fig_sizes = [
                        360 890            % 1: control panel
                        GUI.fig_size_basic % 2: observer
                        GUI.fig_size_basic % 3: camera
                        GUI.fig_size_basic % 4: filter transmissions
                        GUI.fig_size_basic % 5: photo histograms
                        GUI.fig_size_basic % 6: image
                        GUI.fig_size_basic % 7: mesh
                        GUI.fig_size_basic % 8: SPDs
                        GUI.fig_size_basic % 9: reflectances (optional)
                    ];
    
    %% Constants
    
    lambda_lims = [420, 660]; % nm, wavelength limits
    Photo.RAW_black_level = 2048; % the level corresponding to pure black, i.e. zero count
    
    %% GUI Setup

    GUI.label_dims = [GUI.input_x-GUI.label_x, GUI.input_dims(2)];
    GUI.gap_small = GUI.gap_small + GUI.input_dims(2);
    GUI.gap_large = GUI.gap_large + GUI.input_dims(2);
    
    figure(1)
        set(gcf,'Name','Control Panel','NumberTitle','off')
        clf
        set(gcf,'color','white')
        
    %% Main inputs

    Select_Filters.pos = [GUI.input_x, GUI.fig_sizes(1,2)-40, GUI.input_dims];
    Select_Filters.vals = {
                            'ThorLabs Qty. 7 CWL 420:40:660 FWHM 10'
                          };
    uicontrol('Style','text', 'String','Filters', 'Position',[GUI.label_x, Select_Filters.pos(2)-GUI.label_off_vert, GUI.label_dims], 'BackgroundColor','w', 'FontSize',GUI.fs,'HorizontalAlignment','left');
    Select_Filters.handle = uicontrol('Style','popupmenu', 'String',Select_Filters.vals, 'Value',1, 'Position',Select_Filters.pos, 'BackgroundColor',GUI.col_bac, 'FontSize',GUI.fs);
    set(Select_Filters.handle,'Callback',@(hObject,eventdata) update_filters)
    
    Select_Camera.pos = [GUI.input_x, Select_Filters.pos(2)-GUI.gap_small, GUI.input_dims];
    Select_Camera.vals = {
                            'Canon 1DMarkIII'
                            'Canon 20D'
                            'Canon 300D'
                            'Canon 40D'
                            'Canon 500D'
                            'Canon 50D'
                            'Canon 5DMarkII'
                            'Canon 600D'
                            'Canon 60D'
                            'Hasselblad H2'
                            'Nikon D3X'
                            'Nikon D200'
                            'Nikon D3'
                            'Nikon D300s'
                            'Nikon D40'
                            'Nikon D50'
                            'Nikon D5100'
                            'Nikon D700'
                            'Nikon D80'
                            'Nikon D90'
                            'Nokia N900'
                            'Olympus E-PL2'
                            'Pentax K-5'
                            'Pentax Q'
                            'Point Grey Grasshopper 50S5C'
                            'Point Grey Grasshopper2 14S5C'
                            'Phase One'
                            'SONY NEX-5N'
                            'Canon 650D'
                         };
    uicontrol('Style','text', 'String','Camera', 'Position',[GUI.label_x, Select_Camera.pos(2)-GUI.label_off_vert, GUI.label_dims], 'BackgroundColor','w', 'FontSize',GUI.fs,'HorizontalAlignment','left');
    Select_Camera.handle = uicontrol('Style','popupmenu', 'String',Select_Camera.vals, 'Value',29, 'Position',Select_Camera.pos, 'BackgroundColor',GUI.col_bac, 'FontSize',GUI.fs);
    set(Select_Camera.handle,'Callback',@(hObject,eventdata) update_camera)
    
    Select_Observer.pos = [GUI.input_x, Select_Camera.pos(2)-GUI.gap_small, GUI.input_dims];
    Select_Observer.vals = {'CIE 1931 2� XYZ','CIE 1964 10� XYZ'};
    uicontrol('Style','text', 'String','Observer', 'Position',[GUI.label_x, Select_Observer.pos(2)-GUI.label_off_vert, GUI.label_dims], 'BackgroundColor','w', 'FontSize',GUI.fs,'HorizontalAlignment','left');
    Select_Observer.handle = uicontrol('Style','popupmenu', 'String',Select_Observer.vals, 'Position',Select_Observer.pos, 'BackgroundColor',GUI.col_bac, 'FontSize',GUI.fs);
    set(Select_Observer.handle,'Callback',@(hObject,eventdata) update_observer)
    
    Load_Photos.pos = [GUI.input_x, Select_Observer.pos(2)-GUI.gap_small, GUI.input_dims];
    uicontrol('Style','text', 'String','Photos', 'Position',[GUI.label_x, Load_Photos.pos(2)-GUI.label_off_vert, GUI.label_dims], 'BackgroundColor','w', 'FontSize',GUI.fs,'HorizontalAlignment','left');
    Load_Photos.handle = uicontrol('Style','pushbutton', 'String','Load Photos', 'Position',Load_Photos.pos, 'BackgroundColor',GUI.col_bac, 'FontSize',GUI.fs);
    set(Load_Photos.handle,'Callback',@(hObject,eventdata) load_photos)

    %% Resolutions
    
    Preview_Res.pos = [GUI.input_x, Load_Photos.pos(2)-GUI.gap_large, GUI.input_dims];
    uicontrol('Style','text', 'String','Preview Res, px', 'Position',[GUI.label_x, Preview_Res.pos(2)-GUI.label_off_vert, GUI.label_dims], 'BackgroundColor','w', 'FontSize',GUI.fs,'HorizontalAlignment','left');
    Preview_Res.handle = uicontrol('Style','edit', 'String','500', 'Position',Preview_Res.pos, 'BackgroundColor',GUI.col_bac, 'FontSize',GUI.fs);
    
    Export_Res.pos = [GUI.input_x, Preview_Res.pos(2)-GUI.gap_small, GUI.input_dims];
    uicontrol('Style','text', 'String','Export Res, px', 'Position',[GUI.label_x, Export_Res.pos(2)-GUI.label_off_vert, GUI.label_dims], 'BackgroundColor','w', 'FontSize',GUI.fs,'HorizontalAlignment','left');
    Export_Res.handle = uicontrol('Style','edit', 'String','2000', 'Position',Export_Res.pos, 'BackgroundColor',GUI.col_bac, 'FontSize',GUI.fs);
    
    Wavelength_Res.pos = [GUI.input_x, Export_Res.pos(2)-GUI.gap_small, GUI.input_dims];
    Wavelength_Res.vals = {'1','2','5','10','20'};
    uicontrol('Style','text', 'String','Wavelength Res, nm', 'Position',[GUI.label_x, Wavelength_Res.pos(2)-GUI.label_off_vert, GUI.label_dims], 'BackgroundColor','w', 'FontSize',GUI.fs,'HorizontalAlignment','left');
    Wavelength_Res.handle = uicontrol('Style','popupmenu', 'String',Wavelength_Res.vals, 'Value',3, 'Position',Wavelength_Res.pos, 'BackgroundColor',GUI.col_bac, 'FontSize',GUI.fs);
    set(Wavelength_Res.handle,'Callback',@(hObject,eventdata) update_wavelength)
    
    CWL_Res.pos = [GUI.input_x, Wavelength_Res.pos(2)-GUI.gap_small, GUI.input_dims];
    uicontrol('Style','text', 'String','CWL Res, nm', 'Position',[GUI.label_x, CWL_Res.pos(2)-GUI.label_off_vert, GUI.label_dims], 'BackgroundColor','w', 'FontSize',GUI.fs,'HorizontalAlignment','left');
    CWL_Res.handle = uicontrol('Style','edit', 'String','10', 'Position',CWL_Res.pos, 'BackgroundColor',GUI.col_bac, 'FontSize',GUI.fs);
    set(CWL_Res.handle,'Callback',@(hObject,eventdata) update_sensor)
    
    %% Reflectance
    
    Reflectance_Toggle.pos = [GUI.input_x, CWL_Res.pos(2)-GUI.gap_large, GUI.input_dims];
    uicontrol('Style','text', 'String','Calculate Reflectance', 'Position',[GUI.label_x, Reflectance_Toggle.pos(2)-GUI.label_off_vert, GUI.label_dims], 'BackgroundColor','w', 'FontSize',GUI.fs,'HorizontalAlignment','left');
    Reflectance_Toggle.handle = uicontrol('Style','checkbox', 'Value', 0, 'String','', 'Position',Reflectance_Toggle.pos, 'BackgroundColor',GUI.col_bac, 'FontSize',GUI.fs);
    
    Select_Illuminant.pos = [GUI.input_x, Reflectance_Toggle.pos(2)-GUI.gap_small, GUI.input_dims];
    Select_Illuminant.vals = {'A' 'C' 'D50' 'D55' 'D65' 'D75'};
    uicontrol('Style','text', 'String','Illuminant', 'Position',[GUI.label_x, Select_Illuminant.pos(2)-GUI.label_off_vert, GUI.label_dims], 'BackgroundColor','w', 'FontSize',GUI.fs,'HorizontalAlignment','left');
    Select_Illuminant.handle = uicontrol('Style','popupmenu', 'String',Select_Illuminant.vals, 'Value',5, 'Position',Select_Illuminant.pos, 'BackgroundColor',GUI.col_bac, 'FontSize',GUI.fs);

    %% Camera gains
    
    Interpolation_Method.pos = [GUI.input_x, Select_Illuminant.pos(2)-GUI.gap_large, GUI.input_dims];
    Interpolation_Method.vals = {'linear','spline','pchip'};
    uicontrol('Style','text', 'String','Interpolation Method', 'Position',[GUI.label_x, Interpolation_Method.pos(2)-GUI.label_off_vert, GUI.label_dims], 'BackgroundColor','w', 'FontSize',GUI.fs,'HorizontalAlignment','left');
    Interpolation_Method.handle = uicontrol('Style','popupmenu', 'String',Interpolation_Method.vals, 'Value',3, 'Position',Interpolation_Method.pos, 'BackgroundColor',GUI.col_bac, 'FontSize',GUI.fs);
    
    Zero_Slope_Toggle.pos = [GUI.input_x, Interpolation_Method.pos(2)-GUI.gap_small, GUI.input_dims];
    uicontrol('Style','text', 'String','Zero Slope Toggle', 'Position',[GUI.label_x, Zero_Slope_Toggle.pos(2)-GUI.label_off_vert, GUI.label_dims], 'BackgroundColor','w', 'FontSize',GUI.fs,'HorizontalAlignment','left');
    Zero_Slope_Toggle.handle = uicontrol('Style','checkbox', 'Value', 0, 'String','', 'Position',Zero_Slope_Toggle.pos, 'BackgroundColor',GUI.col_bac, 'FontSize',GUI.fs);
    
    Zero_Slope_Fraction.pos = [GUI.input_x, Zero_Slope_Toggle.pos(2)-GUI.gap_small, GUI.input_dims];
    uicontrol('Style','text', 'String','Zero Slope Fraction', 'Position',[GUI.label_x, Zero_Slope_Fraction.pos(2)-GUI.label_off_vert, GUI.label_dims], 'BackgroundColor','w', 'FontSize',GUI.fs,'HorizontalAlignment','left');
    Zero_Slope_Fraction.handle = uicontrol('Style','edit', 'String','1.0', 'Position',Zero_Slope_Fraction.pos, 'BackgroundColor',GUI.col_bac, 'FontSize',GUI.fs);
    
    %% Value scaling
    
    Gamma.pos = [GUI.input_x, Zero_Slope_Fraction.pos(2)-GUI.gap_large, GUI.input_dims];
    uicontrol('Style','text', 'String','Gamma', 'Position',[GUI.label_x, Gamma.pos(2)-GUI.label_off_vert, GUI.label_dims], 'BackgroundColor','w', 'FontSize',GUI.fs,'HorizontalAlignment','left');
    Gamma.handle = uicontrol('Style','edit', 'String','1.00', 'Position',Gamma.pos, 'BackgroundColor',GUI.col_bac, 'FontSize',GUI.fs);
    
    Fraction_Saturated_Low.pos = [GUI.input_x, Gamma.pos(2)-GUI.gap_small, GUI.input_dims];
    uicontrol('Style','text', 'String','Fraction Saturated, Low', 'Position',[GUI.label_x, Fraction_Saturated_Low.pos(2)-GUI.label_off_vert, GUI.label_dims], 'BackgroundColor','w', 'FontSize',GUI.fs,'HorizontalAlignment','left');
    Fraction_Saturated_Low.handle = uicontrol('Style','edit', 'String','0.01', 'Position',Fraction_Saturated_Low.pos, 'BackgroundColor',GUI.col_bac, 'FontSize',GUI.fs);
    
    Fraction_Saturated_High.pos = [GUI.input_x, Fraction_Saturated_Low.pos(2)-GUI.gap_small, GUI.input_dims];
    uicontrol('Style','text', 'String','Fraction Saturated, High', 'Position',[GUI.label_x, Fraction_Saturated_High.pos(2)-GUI.label_off_vert, GUI.label_dims], 'BackgroundColor','w', 'FontSize',GUI.fs,'HorizontalAlignment','left');
    Fraction_Saturated_High.handle = uicontrol('Style','edit', 'String','0.01', 'Position',Fraction_Saturated_High.pos, 'BackgroundColor',GUI.col_bac, 'FontSize',GUI.fs);

    Value_Low.pos = [GUI.input_x, Fraction_Saturated_High.pos(2)-GUI.gap_small, GUI.input_dims];
    uicontrol('Style','text', 'String','Value, Low', 'Position',[GUI.label_x, Value_Low.pos(2)-GUI.label_off_vert, GUI.label_dims], 'BackgroundColor','w', 'FontSize',GUI.fs,'HorizontalAlignment','left');
    Value_Low.handle = uicontrol('Style','edit', 'String','0.05', 'Position',Value_Low.pos, 'BackgroundColor',GUI.col_bac, 'FontSize',GUI.fs);
    
    Value_High.pos = [GUI.input_x, Value_Low.pos(2)-GUI.gap_small, GUI.input_dims];
    uicontrol('Style','text', 'String','Value, High', 'Position',[GUI.label_x, Value_High.pos(2)-GUI.label_off_vert, GUI.label_dims], 'BackgroundColor','w', 'FontSize',GUI.fs,'HorizontalAlignment','left');
    Value_High.handle = uicontrol('Style','edit', 'String','0.95', 'Position',Value_High.pos, 'BackgroundColor',GUI.col_bac, 'FontSize',GUI.fs);
    
    %% Outputs
  
    Mesh_Density.pos = [GUI.input_x, Value_High.pos(2)-GUI.gap_large, GUI.input_dims];
    uicontrol('Style','text', 'String','Mesh Density, pt/side', 'Position',[GUI.label_x, Mesh_Density.pos(2)-GUI.label_off_vert, GUI.label_dims], 'BackgroundColor','w', 'FontSize',GUI.fs,'HorizontalAlignment','left');
    Mesh_Density.handle = uicontrol('Style','edit', 'String','10', 'Position',Mesh_Density.pos, 'BackgroundColor',GUI.col_bac, 'FontSize',GUI.fs);

    Mesh_Sample_Window.pos = [GUI.input_x, Mesh_Density.pos(2)-GUI.gap_small, GUI.input_dims];
    uicontrol('Style','text', 'String','Mesh Smpl. Window, px', 'Position',[GUI.label_x, Mesh_Sample_Window.pos(2)-GUI.label_off_vert, GUI.label_dims], 'BackgroundColor','w', 'FontSize',GUI.fs,'HorizontalAlignment','left');
    Mesh_Sample_Window.handle = uicontrol('Style','edit', 'String','10', 'Position',Mesh_Sample_Window.pos, 'BackgroundColor',GUI.col_bac, 'FontSize',GUI.fs);
    
    Custom_Mesh_Toggle.pos = [GUI.input_x, Mesh_Sample_Window.pos(2)-GUI.gap_small, GUI.input_dims];
    uicontrol('Style','text', 'String','Custom Mesh Toggle', 'Position',[GUI.label_x, Custom_Mesh_Toggle.pos(2)-GUI.label_off_vert, GUI.label_dims], 'BackgroundColor','w', 'FontSize',GUI.fs,'HorizontalAlignment','left');
    Custom_Mesh_Toggle.handle = uicontrol('Style','checkbox', 'Value', 0, 'String','', 'Position',Custom_Mesh_Toggle.pos, 'BackgroundColor',GUI.col_bac, 'FontSize',GUI.fs);
    
    Custom_Mesh_x.pos = [GUI.input_x, Custom_Mesh_Toggle.pos(2)-GUI.gap_small, GUI.input_dims];
    uicontrol('Style','text', 'String','Custom Mesh x, px', 'Position',[GUI.label_x, Custom_Mesh_x.pos(2)-GUI.label_off_vert, GUI.label_dims], 'BackgroundColor','w', 'FontSize',GUI.fs,'HorizontalAlignment','left');
    Custom_Mesh_x.handle = uicontrol('Style','edit', 'String','', 'Position',Custom_Mesh_x.pos, 'BackgroundColor',GUI.col_bac, 'FontSize',GUI.fs);
    
    Custom_Mesh_y.pos = [GUI.input_x, Custom_Mesh_x.pos(2)-GUI.gap_small, GUI.input_dims];
    uicontrol('Style','text', 'String','Custom Mesh y, px', 'Position',[GUI.label_x, Custom_Mesh_y.pos(2)-GUI.label_off_vert, GUI.label_dims], 'BackgroundColor','w', 'FontSize',GUI.fs,'HorizontalAlignment','left');
    Custom_Mesh_y.handle = uicontrol('Style','edit', 'String','', 'Position',Custom_Mesh_y.pos, 'BackgroundColor',GUI.col_bac, 'FontSize',GUI.fs);
    
    %% Execution/Control
    
    Preview_Image.pos = [GUI.input_x, Custom_Mesh_y.pos(2)-GUI.gap_large, GUI.input_dims];
    Preview_Image.handle = uicontrol('Style','pushbutton', 'String','Preview Image', 'Position',Preview_Image.pos, 'BackgroundColor',GUI.col_hi, 'FontSize',GUI.fs);
    set(Preview_Image.handle,'Callback',@(hObject,eventdata) preview_image)
    
    Export_Image.pos = [GUI.input_x, Preview_Image.pos(2)-GUI.gap_small, GUI.input_dims];
    Export_Image.handle = uicontrol('Style','pushbutton', 'String','Export Image', 'Position',Export_Image.pos, 'BackgroundColor',GUI.col_hi, 'FontSize',GUI.fs);
    set(Export_Image.handle,'Callback',@(hObject,eventdata) export_image)
    
    Reset_Controls.pos = [GUI.input_x, Export_Image.pos(2)-GUI.gap_large, GUI.input_dims];
    Reset_Controls.handle = uicontrol('Style','pushbutton', 'String','Reset Controls', 'Position',Reset_Controls.pos, 'BackgroundColor',GUI.col_bac, 'FontSize',GUI.fs);
    set(Reset_Controls.handle,'Callback',@(hObject,eventdata) reset_controls)
    
    Reset_Figures.pos = [GUI.input_x, Reset_Controls.pos(2)-GUI.gap_small, GUI.input_dims];
    Reset_Figures.handle = uicontrol('Style','pushbutton', 'String','Reset Figures', 'Position',Reset_Figures.pos, 'BackgroundColor',GUI.col_bac, 'FontSize',GUI.fs);
    set(Reset_Figures.handle,'Callback',@(hObject,eventdata) reset_figures)
    
    Close_Figures.pos = [GUI.input_x, Reset_Figures.pos(2)-GUI.gap_small, GUI.input_dims];
    Close_Figures.handle = uicontrol('Style','pushbutton', 'String','Close Figures', 'Position',Close_Figures.pos, 'BackgroundColor',GUI.col_bac, 'FontSize',GUI.fs);
    set(Close_Figures.handle,'Callback',@(hObject,eventdata) close_figures)
    
    Exit_Program.pos = [GUI.input_x, Close_Figures.pos(2)-GUI.gap_small, GUI.input_dims];
    Exit_Program.handle = uicontrol('Style','pushbutton', 'String','Exit Program', 'Position',Exit_Program.pos, 'BackgroundColor',GUI.col_bac, 'FontSize',GUI.fs);
    set(Exit_Program.handle,'Callback',@(hObject,eventdata) exit_program)
    
    %% Main body
    
    update_wavelength
    reset_figures
    
    %% Supporting functions below
    
    function update_wavelength
        
        Wavelength = min(lambda_lims) : str2double(Wavelength_Res.vals{get(Wavelength_Res.handle, 'value')}) : max(lambda_lims);
        Wavelength = Wavelength'; % to column vector
        update_observer
        update_filters
        update_camera
        update_sensor
        
        % Send structures to workspace
        assignin('base','Wavelength', Wavelength)
        assignin('base','Observer',   Observer)
        assignin('base','Photo',      Photo)
        assignin('base','Filter',     Filter)
        assignin('base','Image',      Image)
        assignin('base','Camera',     Camera)
        assignin('base','Sensor',     Sensor)
        assignin('base','HSDC',       HSDC)
        
    end

    %%

    function update_sensor
        
        % Take dot product of S (camera sensitivities) and T (filter transmissions)
        domain = 400 : 1 : 700;
        Sensor.S_dot_T = zeros(Filter.qty, 3);
        for cc = 1 : 3
            
            S = Camera.Sen_orig(:,cc);
            x_wider = [min(domain) Camera.lam_orig max(domain)];
            x_wider = unique(x_wider);
            S = interp1(Camera.lam_orig, S, x_wider, 'linear','extrap'); % coarse linear extrapolation
            S = interp1(x_wider, S, domain, 'pchip'); % fine pchip interpolation
            S(S<0) = 0;
            
            for i_lam = 1 : Filter.qty
                T = interp1(Filter.lam_orig, Filter.T_orig(:,i_lam), domain);
                Sensor.S_dot_T(i_lam,cc) = dot(S, T);
            end
        end

    end
    
    %% Figure control
    
    function reset_controls
        
        set(Select_Filters.handle,          'value',  1)
        set(Select_Camera.handle,           'value',  29)
        set(Select_Observer.handle,         'value',  1)
        set(Preview_Res.handle,             'string', 500)
        set(Export_Res.handle,              'string', 2000)
        set(Wavelength_Res.handle,          'value',  3)
        set(CWL_Res.handle,                 'string', 10)
        set(Reflectance_Toggle.handle,      'value',  0)
        set(Select_Illuminant.handle,       'value',  5)
        set(Zero_Slope_Toggle.handle,       'value',  0)
        set(Zero_Slope_Fraction.handle,     'string', '1.0')
        set(Gamma.handle,                   'string', '1.00')
        set(Fraction_Saturated_Low.handle,  'string', '0.01')
        set(Fraction_Saturated_High.handle, 'string', '0.01')
        set(Value_Low.handle,               'string', '0.05')
        set(Value_High.handle,              'string', '0.95')
        set(Mesh_Density.handle,            'string', '10')
        set(Mesh_Sample_Window.handle,      'string', '10')
        set(Custom_Mesh_Toggle.handle,      'value',  0)
        set(Custom_Mesh_x.handle,           'string', '')
        set(Custom_Mesh_y.handle,           'string', '')
        
    end
    
    function close_figures
        fig_handles = findobj('Type', 'figure');
        for f = 1 : length(fig_handles)
            figure(f)
            if ~strcmp(get(gcf,'name'),'Control Panel')
                close
            end
        end
    end
    
    function exit_program
        close all
    end

    function reset_figures
        
        fig_handles = findobj('Type', 'figure');
        screen_res = get(0,'screensize');
        screen_res = screen_res(3:4); % px, [width, height]
        
        dp = [29, -29]; % px, cascade offset
        oc = [18 100]; % px, offset from corner
        
        % Position first figure
        figure(1)
        xy = [oc(1), screen_res(2)-oc(2)-GUI.fig_sizes(1,2)];
        set(gcf,'position',[xy, GUI.fig_sizes(1,:)]);
        
        % Define special offset for second figure to prevent cascading on
        % top of control panel
        xy = [oc(1)*2.5 + GUI.fig_sizes(1,1), screen_res(2)-oc(2)-GUI.fig_sizes(2,2)];
        
        for f = 2 : length(fig_handles)
            figure(f)
            set(gcf,'position',[xy GUI.fig_sizes(f,:)]);
            xy = xy + dp;
        end
        
    end

    %% Image settings

    function preview_image
        if ~isfield(Photo, 'RGB_calc')
            warning('No photos loaded, cannot generate image')
            return
        end
        Image.mode = 'preview';
        Photo.scale = str2double(get(Preview_Res.handle,'string')) / max(Photo.res_orig);
        generate_image
    end

    function export_image
        if ~isfield(Photo, 'RGB_calc')
            warning('No photos loaded, cannot generate image')
            return
        end
        Image.mode = 'export';
        Photo.scale = str2double(get(Export_Res.handle,'string')) / max(Photo.res_orig);
        generate_image
    end

    %% Image generation

    function generate_image

        % The core function in which the HSDC and reconstructed image are
        % calculated and sampled
        
        % Rescale all photos in width and height, if necessary
        Photo.RGB = cell(size(Photo.RGB_calc));
        for p = 1 : Photo.qty
            if Photo.scale < 1
                Photo.RGB{p} = imresize(Photo.RGB_calc{p}, Photo.scale);
            else
                Photo.RGB{p} = Photo.RGB_calc{p};
            end
        end
        Photo.res = [size(Photo.RGB{1},1), size(Photo.RGB{1},2)];
        
        qty_lam_calc   = length(Filter.CWL); % coarse
        qty_lam_report = length(Wavelength); % fine

        % Calculate HSDC from RAW values
        HSDC = zeros(Photo.res(1), Photo.res(2), qty_lam_calc); % initialize datacube
        for w = 1 : qty_lam_calc % for each wavelength
            RGB = double(Photo.RGB{w});
            for cc = 1 : 3
                S_cc = Camera.sensitivity(Filter.ind_CWL(w),cc);
                HSDC(:,:,w) = HSDC(:,:,w) + (RGB(:,:,cc).*S_cc) ./ Sensor.S_dot_T(w,cc);
            end
            S_sum = sum(Camera.sensitivity(Filter.ind_CWL(w),:));
            HSDC(:,:,w) = HSDC(:,:,w) ./ S_sum;
        end
        
        % Enforce zero mean HSDC slope if requested
        if get(Zero_Slope_Toggle.handle,'value')
            zero_slope_fraction = str2double(get(Zero_Slope_Fraction.handle,'string')); % 0: no change; 1: full change
            SPD_mean = sum(sum(HSDC,1),2);
            SPD_mean = squeeze(SPD_mean);
            SPD_mean = SPD_mean ./ prod(Photo.res);
            SPD_mean = reshape(SPD_mean, [1,1,Filter.qty]);
            SPD_mean = repmat(SPD_mean, [Photo.res,1]);
            SPD_     = HSDC ./ SPD_mean;
            HSDC = (1-zero_slope_fraction).*HSDC./max(HSDC(:)) + zero_slope_fraction.*SPD_./max(SPD_(:));
        end
        
        % Set indices for interpolation vs. extrapolation
        h = waitbar(0,'Interpolating and extrapolating datacube...');
        i_interp = intersect(find(Wavelength>=min(Filter.CWL)), find(Wavelength<=max(Filter.CWL)));
        i_extrap = setdiff(1:length(Wavelength), i_interp);
        
        % Interpolate within filter domain
        [X,  Y,  W]  = meshgrid(1:Photo.res(2), 1:Photo.res(1), Wavelength(Filter.ind_CWL));
        [Xq, Yq, Wq] = meshgrid(1:Photo.res(2), 1:Photo.res(1), Wavelength(i_interp));
        if ~isequal(W, Wq)
            switch get(Interpolation_Method.handle, 'value')
                case 1; 
                    interp_method = 'linear';
                case 2
                    interp_method = 'spline';
                case 3
                    interp_method = 'pchip';
                otherwise
                    error('Invalid interpolation method')
            end
            
            % Workaround specific to R2015a which inconsistently supports
            % cubic vs. pchip depending on 1D vs. 3D interp
            if strcmp(interp_method,'pchip')
                HSDC = interp3(X, Y, W, HSDC, Xq, Yq, Wq, 'cubic');
            else
                HSDC = interp3(X, Y, W, HSDC, Xq, Yq, Wq, interp_method);
            end
            
        end
        
        % Extrapolate beyond filter domain
        if ~isempty(i_extrap)
            % Hold closest defined value as constant, rather than linear or
            % spline extrapolation, which is not well-defined.
            SPD_ = zeros(Photo.res(1), Photo.res(2), qty_lam_report);
            i_mid = round(qty_lam_report/2);
            SPD_(:,:,1:i_mid)       = repmat(HSDC(:,:,1),   [1,1,length(1:i_mid)]);
            SPD_(:,:,(i_mid+1):qty_lam_report) = repmat(HSDC(:,:,end), [1,1,length((i_mid+1):qty_lam_report)]);
            SPD_(:,:,i_interp) = HSDC; % paste interpolated data in correct place
            HSDC = SPD_;
        end
        
        close(h)

        % Normalize
        HSDC = HSDC ./ max(HSDC(:));
        
        % Calculate reflectance if requested
        if get(Reflectance_Toggle.handle, 'value')
            
            switch get(Select_Illuminant.handle, 'value')
                case 1 % A
                    Illuminant.lambda = [300 301 302 303 304 305 306 307 308 309 310 311 312 313 314 315 316 317 318 319 320 321 322 323 324 325 326 327 328 329 330 331 332 333 334 335 336 337 338 339 340 341 342 343 344 345 346 347 348 349 350 351 352 353 354 355 356 357 358 359 360 361 362 363 364 365 366 367 368 369 370 371 372 373 374 375 376 377 378 379 380 381 382 383 384 385 386 387 388 389 390 391 392 393 394 395 396 397 398 399 400 401 402 403 404 405 406 407 408 409 410 411 412 413 414 415 416 417 418 419 420 421 422 423 424 425 426 427 428 429 430 431 432 433 434 435 436 437 438 439 440 441 442 443 444 445 446 447 448 449 450 451 452 453 454 455 456 457 458 459 460 461 462 463 464 465 466 467 468 469 470 471 472 473 474 475 476 477 478 479 480 481 482 483 484 485 486 487 488 489 490 491 492 493 494 495 496 497 498 499 500 501 502 503 504 505 506 507 508 509 510 511 512 513 514 515 516 517 518 519 520 521 522 523 524 525 526 527 528 529 530 531 532 533 534 535 536 537 538 539 540 541 542 543 544 545 546 547 548 549 550 551 552 553 554 555 556 557 558 559 560 561 562 563 564 565 566 567 568 569 570 571 572 573 574 575 576 577 578 579 580 581 582 583 584 585 586 587 588 589 590 591 592 593 594 595 596 597 598 599 600 601 602 603 604 605 606 607 608 609 610 611 612 613 614 615 616 617 618 619 620 621 622 623 624 625 626 627 628 629 630 631 632 633 634 635 636 637 638 639 640 641 642 643 644 645 646 647 648 649 650 651 652 653 654 655 656 657 658 659 660 661 662 663 664 665 666 667 668 669 670 671 672 673 674 675 676 677 678 679 680 681 682 683 684 685 686 687 688 689 690 691 692 693 694 695 696 697 698 699 700 701 702 703 704 705 706 707 708 709 710 711 712 713 714 715 716 717 718 719 720 721 722 723 724 725 726 727 728 729 730 731 732 733 734 735 736 737 738 739 740 741 742 743 744 745 746 747 748 749 750 751 752 753 754 755 756 757 758 759 760 761 762 763 764 765 766 767 768 769 770 771 772 773 774 775 776 777 778 779 780 781 782 783 784 785 786 787 788 789 790 791 792 793 794 795 796 797 798 799 800 801 802 803 804 805 806 807 808 809 810 811 812 813 814 815 816 817 818 819 820 821 822 823 824 825 826 827 828 829 830];
                    Illuminant.power  = [0.930483 0.967643 1.00597 1.04549 1.08623 1.12821 1.17147 1.21602 1.26188 1.3091 1.35769 1.40768 1.4591 1.51198 1.56633 1.62219 1.67959 1.73855 1.7991 1.86127 1.92508 1.99057 2.05776 2.12667 2.19734 2.2698 2.34406 2.42017 2.49814 2.57801 2.65981 2.74355 2.82928 2.91701 3.00678 3.09861 3.19253 3.28857 3.38676 3.48712 3.58968 3.69447 3.80152 3.91085 4.0225 4.13648 4.25282 4.37156 4.49272 4.61631 4.74238 4.87095 5.00204 5.13568 5.27189 5.4107 5.55213 5.69622 5.84298 5.99244 6.14462 6.29955 6.45724 6.61774 6.78105 6.9472 7.11621 7.28811 7.46292 7.64066 7.82135 8.00501 8.19167 8.38134 8.57404 8.7698 8.96864 9.17056 9.37561 9.58378 9.7951 10.0096 10.2273 10.4481 10.6722 10.8996 11.1302 11.364 11.6012 11.8416 12.0853 12.3324 12.5828 12.8366 13.0938 13.3543 13.6182 13.8855 14.1563 14.4304 14.708 14.9891 15.2736 15.5616 15.853 16.148 16.4464 16.7484 17.0538 17.3628 17.6753 17.9913 18.3108 18.6339 18.9605 19.2907 19.6244 19.9617 20.3026 20.647 20.995 21.3465 21.7016 22.0603 22.4225 22.7883 23.1577 23.5307 23.9072 24.2873 24.6709 25.0581 25.4489 25.8432 26.2411 26.6425 27.0475 27.456 27.8681 28.2836 28.7027 29.1253 29.5515 29.9811 30.4142 30.8508 31.2909 31.7345 32.1815 32.632 33.0859 33.5432 34.004 34.4682 34.9358 35.4068 35.8811 36.3588 36.8399 37.3243 37.8121 38.3031 38.7975 39.2951 39.796 40.3002 40.8076 41.3182 41.832 42.3491 42.8693 43.3926 43.9192 44.4488 44.9816 45.5174 46.0563 46.5983 47.1433 47.6913 48.2423 48.7963 49.3533 49.9132 50.476 51.0418 51.6104 52.1818 52.7561 53.3332 53.9132 54.4958 55.0813 55.6694 56.2603 56.8539 57.4501 58.0489 58.6504 59.2545 59.8611 60.4703 61.082 61.6962 62.3128 62.932 63.5535 64.1775 64.8038 65.4325 66.0635 66.6968 67.3324 67.9702 68.6102 69.2525 69.8969 70.5435 71.1922 71.843 72.4959 73.1508 73.8077 74.4666 75.1275 75.7903 76.4551 77.1217 77.7902 78.4605 79.1326 79.8065 80.4821 81.1595 81.8386 82.5193 83.2017 83.8856 84.5712 85.2584 85.947 86.6372 87.3288 88.0219 88.7165 89.4124 90.1097 90.8083 91.5082 92.2095 92.912 93.6157 94.3206 95.0267 95.7339 96.4423 97.1518 97.8623 98.5739 99.2864 100 100.715 101.43 102.146 102.864 103.582 104.301 105.02 105.741 106.462 107.184 107.906 108.63 109.354 110.078 110.803 111.529 112.255 112.982 113.709 114.436 115.164 115.893 116.622 117.351 118.08 118.81 119.54 120.27 121.001 121.731 122.462 123.193 123.924 124.655 125.386 126.118 126.849 127.58 128.312 129.043 129.774 130.505 131.236 131.966 132.697 133.427 134.157 134.887 135.617 136.346 137.075 137.804 138.532 139.26 139.988 140.715 141.441 142.167 142.893 143.618 144.343 145.067 145.79 146.513 147.235 147.957 148.678 149.398 150.117 150.836 151.554 152.271 152.988 153.704 154.418 155.132 155.845 156.558 157.269 157.979 158.689 159.397 160.104 160.811 161.516 162.221 162.924 163.626 164.327 165.028 165.726 166.424 167.121 167.816 168.51 169.203 169.895 170.586 171.275 171.963 172.65 173.335 174.019 174.702 175.383 176.063 176.741 177.419 178.094 178.769 179.441 180.113 180.783 181.451 182.118 182.783 183.447 184.109 184.77 185.429 186.087 186.743 187.397 188.05 188.701 189.35 189.998 190.644 191.288 191.931 192.572 193.211 193.849 194.484 195.118 195.75 196.381 197.009 197.636 198.261 198.884 199.506 200.125 200.743 201.359 201.972 202.584 203.195 203.803 204.409 205.013 205.616 206.216 206.815 207.411 208.006 208.599 209.189 209.778 210.365 210.949 211.532 212.112 212.691 213.268 213.842 214.415 214.985 215.553 216.12 216.684 217.246 217.806 218.364 218.92 219.473 220.025 220.574 221.122 221.667 222.21 222.751 223.29 223.826 224.361 224.893 225.423 225.951 226.477 227 227.522 228.041 228.558 229.073 229.585 230.096 230.604 231.11 231.614 232.115 232.615 233.112 233.606 234.099 234.589 235.078 235.564 236.047 236.529 237.008 237.485 237.959 238.432 238.902 239.37 239.836 240.299 240.76 241.219 241.675 242.13 242.582 243.031 243.479 243.924 244.367 244.808 245.246 245.682 246.116 246.548 246.977 247.404 247.829 248.251 248.671 249.089 249.505 249.918 250.329 250.738 251.144 251.548 251.95 252.35 252.747 253.142 253.535 253.925 254.314 254.7 255.083 255.465 255.844 256.221 256.595 256.968 257.338 257.706 258.071 258.434 258.795 259.154 259.511 259.865 260.217 260.567 260.914 261.259 261.602];
                case 2 % C
                    Illuminant.lambda = [300 305 310 315 320 325 330 335 340 345 350 355 360 365 370 375 380 385 390 395 400 405 410 415 420 425 430 435 440 445 450 455 460 465 470 475 480 485 490 495 500 505 510 515 520 525 530 535 540 545 550 555 560 565 570 575 580 585 590 595 600 605 610 615 620 625 630 635 640 645 650 655 660 665 670 675 680 685 690 695 700 705 710 715 720 725 730 735 740 745 750 755 760 765 770 775 780];
                    Illuminant.power  = [0 0 0 0 0.01 0.2 0.4 1.55 2.7 4.85 7 9.95 12.9 17.2 21.4 27.5 33 39.92 47.4 55.17 63.3 71.81 80.6 89.53 98.1 105.8 112.4 117.75 121.5 123.45 124 123.6 123.1 123.3 123.8 124.09 123.9 122.92 120.7 116.9 112.1 106.98 102.3 98.81 96.9 96.78 98 99.94 102.1 103.95 105.2 105.67 105.3 104.11 102.3 100.15 97.8 95.43 93.2 91.22 89.7 88.83 88.4 88.19 88.1 88.06 88 87.86 87.8 87.99 88.2 88.2 87.9 87.22 86.3 85.3 84 82.21 80.2 78.24 76.3 74.36 72.4 70.4 68.3 66.3 64.4 62.8 61.5 60.2 59.2 58.5 58.1 58 58.2 58.5 59.1];
                case 3 % D50
                    Illuminant.lambda = [300 305 310 315 320 325 330 335 340 345 350 355 360 365 370 375 380 385 390 395 400 405 410 415 420 425 430 435 440 445 450 455 460 465 470 475 480 485 490 495 500 505 510 515 520 525 530 535 540 545 550 555 560 565 570 575 580 585 590 595 600 605 610 615 620 625 630 635 640 645 650 655 660 665 670 675 680 685 690 695 700 705 710 715 720 725 730 735 740 745 750 755 760 765 770 775 780];
                    Illuminant.power  = [0.019 1.035 2.051 4.914 7.778 11.263 14.748 16.348 17.948 19.479 21.01 22.476 23.942 25.451 26.961 25.724 24.488 27.179 29.871 39.589 49.308 52.91 56.513 58.273 60.034 58.926 57.818 66.321 74.825 81.036 87.247 88.93 90.612 90.99 91.368 93.238 95.109 93.536 91.963 93.843 95.724 96.169 96.613 96.871 97.129 99.614 102.099 101.427 100.755 101.536 102.317 101.159 100 98.868 97.735 98.327 98.918 96.208 93.499 95.593 97.688 98.478 99.269 99.155 99.042 97.382 95.722 97.29 98.857 97.262 95.667 96.929 98.19 100.597 103.003 101.068 99.133 93.257 87.381 89.492 91.604 92.246 92.889 84.872 76.854 81.683 86.511 89.546 92.58 85.405 78.23 67.961 57.692 70.307 82.923 80.599 78.274];
                case 4 % D55
                    Illuminant.lambda = [300 305 310 315 320 325 330 335 340 345 350 355 360 365 370 375 380 385 390 395 400 405 410 415 420 425 430 435 440 445 450 455 460 465 470 475 480 485 490 495 500 505 510 515 520 525 530 535 540 545 550 555 560 565 570 575 580 585 590 595 600 605 610 615 620 625 630 635 640 645 650 655 660 665 670 675 680 685 690 695 700 705 710 715 720 725 730 735 740 745 750 755 760 765 770 775 780];
                    Illuminant.power  = [0.024 1.048 2.072 6.648 11.224 15.936 20.647 22.266 23.885 25.851 27.817 29.219 30.621 32.464 34.308 33.446 32.584 35.335 38.087 49.518 60.949 64.751 68.554 70.065 71.577 69.746 67.914 76.76 85.605 91.799 97.993 99.228 100.463 100.188 99.913 101.326 102.739 100.409 98.078 99.379 100.68 100.688 100.695 100.341 99.987 102.098 104.21 103.156 102.102 102.535 102.968 101.484 100 98.608 97.216 97.482 97.749 94.59 91.432 92.926 94.419 94.78 95.14 94.68 94.22 92.334 90.448 91.389 92.33 90.592 88.854 89.586 90.317 92.133 93.95 91.953 89.956 84.817 79.677 81.258 82.84 83.842 84.844 77.539 70.235 74.768 79.301 82.147 84.993 78.437 71.88 62.337 52.793 64.36 75.927 73.872 71.818];
                case 5 % D65
                    Illuminant.lambda = [300 301 302 303 304 305 306 307 308 309 310 311 312 313 314 315 316 317 318 319 320 321 322 323 324 325 326 327 328 329 330 331 332 333 334 335 336 337 338 339 340 341 342 343 344 345 346 347 348 349 350 351 352 353 354 355 356 357 358 359 360 361 362 363 364 365 366 367 368 369 370 371 372 373 374 375 376 377 378 379 380 381 382 383 384 385 386 387 388 389 390 391 392 393 394 395 396 397 398 399 400 401 402 403 404 405 406 407 408 409 410 411 412 413 414 415 416 417 418 419 420 421 422 423 424 425 426 427 428 429 430 431 432 433 434 435 436 437 438 439 440 441 442 443 444 445 446 447 448 449 450 451 452 453 454 455 456 457 458 459 460 461 462 463 464 465 466 467 468 469 470 471 472 473 474 475 476 477 478 479 480 481 482 483 484 485 486 487 488 489 490 491 492 493 494 495 496 497 498 499 500 501 502 503 504 505 506 507 508 509 510 511 512 513 514 515 516 517 518 519 520 521 522 523 524 525 526 527 528 529 530 531 532 533 534 535 536 537 538 539 540 541 542 543 544 545 546 547 548 549 550 551 552 553 554 555 556 557 558 559 560 561 562 563 564 565 566 567 568 569 570 571 572 573 574 575 576 577 578 579 580 581 582 583 584 585 586 587 588 589 590 591 592 593 594 595 596 597 598 599 600 601 602 603 604 605 606 607 608 609 610 611 612 613 614 615 616 617 618 619 620 621 622 623 624 625 626 627 628 629 630 631 632 633 634 635 636 637 638 639 640 641 642 643 644 645 646 647 648 649 650 651 652 653 654 655 656 657 658 659 660 661 662 663 664 665 666 667 668 669 670 671 672 673 674 675 676 677 678 679 680 681 682 683 684 685 686 687 688 689 690 691 692 693 694 695 696 697 698 699 700 701 702 703 704 705 706 707 708 709 710 711 712 713 714 715 716 717 718 719 720 721 722 723 724 725 726 727 728 729 730 731 732 733 734 735 736 737 738 739 740 741 742 743 744 745 746 747 748 749 750 751 752 753 754 755 756 757 758 759 760 761 762 763 764 765 766 767 768 769 770 771 772 773 774 775 776 777 778 779 780 781 782 783 784 785 786 787 788 789 790 791 792 793 794 795 796 797 798 799 800 801 802 803 804 805 806 807 808 809 810 811 812 813 814 815 816 817 818 819 820 821 822 823 824 825 826 827 828 829 830];
                    Illuminant.power  = [0.0341 0.36014 0.68618 1.01222 1.33826 1.6643 1.99034 2.31638 2.64242 2.96846 3.2945 4.98865 6.6828 8.37695 10.0711 11.7652 13.4594 15.1535 16.8477 18.5418 20.236 21.9177 23.5995 25.2812 26.963 28.6447 30.3265 32.0082 33.69 35.3717 37.0535 37.343 37.6326 37.9221 38.2116 38.5011 38.7907 39.0802 39.3697 39.6593 39.9488 40.4451 40.9414 41.4377 41.934 42.4302 42.9265 43.4228 43.9191 44.4154 44.9117 45.0844 45.257 45.4297 45.6023 45.775 45.9477 46.1203 46.293 46.4656 46.6383 47.1834 47.7285 48.2735 48.8186 49.3637 49.9088 50.4539 50.9989 51.544 52.0891 51.8777 51.6664 51.455 51.2437 51.0323 50.8209 50.6096 50.3982 50.1869 49.9755 50.4428 50.91 51.3773 51.8446 52.3118 52.7791 53.2464 53.7137 54.1809 54.6482 57.4589 60.2695 63.0802 65.8909 68.7015 71.5122 74.3229 77.1336 79.9442 82.7549 83.628 84.5011 85.3742 86.2473 87.1204 87.9936 88.8667 89.7398 90.6129 91.486 91.6806 91.8752 92.0697 92.2643 92.4589 92.6535 92.8481 93.0426 93.2372 93.4318 92.7568 92.0819 91.4069 90.732 90.057 89.3821 88.7071 88.0322 87.3572 86.6823 88.5006 90.3188 92.1371 93.9554 95.7736 97.5919 99.4102 101.228 103.047 104.865 106.079 107.294 108.508 109.722 110.936 112.151 113.365 114.579 115.794 117.008 117.088 117.169 117.249 117.33 117.41 117.49 117.571 117.651 117.732 117.812 117.517 117.222 116.927 116.632 116.336 116.041 115.746 115.451 115.156 114.861 114.967 115.073 115.18 115.286 115.392 115.498 115.604 115.711 115.817 115.923 115.212 114.501 113.789 113.078 112.367 111.656 110.945 110.233 109.522 108.811 108.865 108.92 108.974 109.028 109.082 109.137 109.191 109.245 109.3 109.354 109.199 109.044 108.888 108.733 108.578 108.423 108.268 108.112 107.957 107.802 107.501 107.2 106.898 106.597 106.296 105.995 105.694 105.392 105.091 104.79 105.08 105.37 105.66 105.95 106.239 106.529 106.819 107.109 107.399 107.689 107.361 107.032 106.704 106.375 106.047 105.719 105.39 105.062 104.733 104.405 104.369 104.333 104.297 104.261 104.225 104.19 104.154 104.118 104.082 104.046 103.641 103.237 102.832 102.428 102.023 101.618 101.214 100.809 100.405 100 99.6334 99.2668 98.9003 98.5337 98.1671 97.8005 97.4339 97.0674 96.7008 96.3342 96.2796 96.225 96.1703 96.1157 96.0611 96.0065 95.9519 95.8972 95.8426 95.788 95.0778 94.3675 93.6573 92.947 92.2368 91.5266 90.8163 90.1061 89.3958 88.6856 88.8177 88.9497 89.0818 89.2138 89.3459 89.478 89.61 89.7421 89.8741 90.0062 89.9655 89.9248 89.8841 89.8434 89.8026 89.7619 89.7212 89.6805 89.6398 89.5991 89.4091 89.219 89.029 88.8389 88.6489 88.4589 88.2688 88.0788 87.8887 87.6987 87.2577 86.8167 86.3757 85.9347 85.4936 85.0526 84.6116 84.1706 83.7296 83.2886 83.3297 83.3707 83.4118 83.4528 83.4939 83.535 83.576 83.6171 83.6581 83.6992 83.332 82.9647 82.5975 82.2302 81.863 81.4958 81.1285 80.7613 80.394 80.0268 80.0456 80.0644 80.0831 80.1019 80.1207 80.1395 80.1583 80.177 80.1958 80.2146 80.4209 80.6272 80.8336 81.0399 81.2462 81.4525 81.6588 81.8652 82.0715 82.2778 81.8784 81.4791 81.0797 80.6804 80.281 79.8816 79.4823 79.0829 78.6836 78.2842 77.4279 76.5716 75.7153 74.859 74.0027 73.1465 72.2902 71.4339 70.5776 69.7213 69.9101 70.0989 70.2876 70.4764 70.6652 70.854 71.0428 71.2315 71.4203 71.6091 71.8831 72.1571 72.4311 72.7051 72.979 73.253 73.527 73.801 74.075 74.349 73.0745 71.8 70.5255 69.251 67.9765 66.702 65.4275 64.153 62.8785 61.604 62.4322 63.2603 64.0885 64.9166 65.7448 66.573 67.4011 68.2293 69.0574 69.8856 70.4057 70.9259 71.446 71.9662 72.4863 73.0064 73.5266 74.0467 74.5669 75.087 73.9376 72.7881 71.6387 70.4893 69.3398 68.1904 67.041 65.8916 64.7421 63.5927 61.8752 60.1578 58.4403 56.7229 55.0054 53.288 51.5705 49.8531 48.1356 46.4182 48.4569 50.4956 52.5344 54.5731 56.6118 58.6505 60.6892 62.728 64.7667 66.8054 66.4631 66.1209 65.7786 65.4364 65.0941 64.7518 64.4096 64.0673 63.7251 63.3828 63.4749 63.567 63.6592 63.7513 63.8434 63.9355 64.0276 64.1198 64.2119 64.304 63.8188 63.3336 62.8484 62.3632 61.8779 61.3927 60.9075 60.4223 59.9371 59.4519 58.7026 57.9533 57.204 56.4547 55.7054 54.9562 54.2069 53.4576 52.7083 51.959 52.5072 53.0553 53.6035 54.1516 54.6998 55.248 55.7961 56.3443 56.8924 57.4406 57.7278 58.015 58.3022 58.5894 58.8765 59.1637 59.4509 59.7381 60.0253 60.3125];
                case 6 % D75
                    Illuminant.lambda = [300 305 310 315 320 325 330 335 340 345 350 355 360 365 370 375 380 385 390 395 400 405 410 415 420 425 430 435 440 445 450 455 460 465 470 475 480 485 490 495 500 505 510 515 520 525 530 535 540 545 550 555 560 565 570 575 580 585 590 595 600 605 610 615 620 625 630 635 640 645 650 655 660 665 670 675 680 685 690 695 700 705 710 715 720 725 730 735 740 745 750 755 760 765 770 775 780];
                    Illuminant.power  = [0.043 2.588 5.133 17.47 29.808 42.369 54.93 56.095 57.259 60 62.74 62.861 62.982 66.647 70.312 68.507 66.703 68.333 69.963 85.946 101.929 106.911 111.894 112.346 112.798 107.945 103.092 112.145 121.198 127.104 133.01 132.682 132.355 129.838 127.322 127.061 126.8 122.291 117.783 117.186 116.589 115.146 113.702 111.181 108.659 109.552 110.445 108.367 106.289 105.596 104.904 102.452 100 97.808 95.616 94.914 94.213 90.605 86.997 87.112 87.227 86.684 86.14 84.861 83.581 81.164 78.747 78.587 78.428 76.614 74.801 74.562 74.324 74.873 75.422 73.499 71.576 67.714 63.852 64.464 65.076 66.573 68.07 62.256 56.443 60.343 64.242 66.697 69.151 63.89 58.629 50.623 42.617 51.985 61.352 59.838 58.324];
                otherwise
                    error('Unrecognized illuminant')
            end
            
            i_x = Wavelength(Filter.ind_CWL);
            i_y = interp1(Illuminant.lambda, Illuminant.power, i_x);
            i_y = interp1(i_x, i_y, Wavelength, interp_method);
            i_y = reshape(i_y, [1,1,size(HSDC,3)]);
            i_y = repmat(i_y, [size(HSDC,1), size(HSDC,2), 1]);
            Reflectance = HSDC ./ i_y;
            Reflectance = Reflectance ./ max(Reflectance(:));
            
        else
            
            Reflectance = nan(size(HSDC));
            
        end
        
        % Generate XYZ colors
        Image.XYZ = zeros(Photo.res(1), Photo.res(2), 3);

        % Reshape along third (wavelength) dimension
        X_C = reshape(Observer.sensitivity(:,1), [1, 1, qty_lam_report]);
        Y_C = reshape(Observer.sensitivity(:,2), [1, 1, qty_lam_report]);
        Z_C = reshape(Observer.sensitivity(:,3), [1, 1, qty_lam_report]);

        % Repeat for each pixel
        X_C = repmat(X_C,[Photo.res, 1]);
        Y_C = repmat(Y_C,[Photo.res, 1]);
        Z_C = repmat(Z_C,[Photo.res, 1]);

        % Index in cell array
        C{1} = X_C;
        C{2} = Y_C;
        C{3} = Z_C;

        for cc = 1 : 3
            Image.XYZ(:,:,cc) = sum(HSDC .* C{cc}, 3);
        end
        
        % Normalize XYZ values
        Image.XYZ = Image.XYZ ./ max(Image.XYZ(:)); % 0 to 1
        
        % Generate RGB image
        Image.RGB = xyz2rgb(Image.XYZ, 'WhitePoint', 'D65');

        % Normalize values
        Image.RGB(Image.RGB < 0) = 0;
        Image.RGB(Image.RGB > 1) = 1;

        % Calculate CDF to determine which portion of value range is actually in use
        I_Gray             = rgb2gray(Image.RGB);
        bin.edges          = linspace(0, 1, 256);
        bin.width          = abs(diff(bin.edges(1:2)));
        [bin.pop,~,bin.ID] = histcounts(I_Gray, bin.edges);
        bin.PDF            = bin.pop ./ sum(bin.pop);
        bin.CDF            = cumsum(bin.PDF);
        frac_sat_lo        = str2double(get(Fraction_Saturated_Low.handle, 'string'));
        frac_sat_hi        = str2double(get(Fraction_Saturated_High.handle,'string'));
        value_range(1)     = str2double(get(Value_Low.handle,              'string'));
        value_range(2)     = str2double(get(Value_High.handle,             'string'));
        bin.ind_active     = intersect(find(bin.CDF>frac_sat_lo), find(bin.CDF<(1-frac_sat_hi)));
        val_lim_active     = [bin.edges(min(bin.ind_active)), bin.edges(max(bin.ind_active))] + bin.width/2;

        % Normalize values
        gamma = str2double(get(Gamma.handle, 'string'));
        Image.RGB = imadjust(Image.RGB, val_lim_active, value_range, gamma);
        Image.RGB(Image.RGB < 0) = 0;
        Image.RGB(Image.RGB > 1) = 1;
        
        figure(6)
            set(gcf,'Name','Reconstructed Image','NumberTitle','off')
            clf
            set(gcf,'color','white')
            image(Image.RGB)
            set(gca,'XTick',[])
            set(gca,'YTick',[])
            axis tight
            axis equal
            set(gca,'position',[0 0 1 1])

        % Create mesh for sampling SPDs
        if get(Custom_Mesh_Toggle.handle,'value') % user requests custom mesh
            
            mesh_x = get(Custom_Mesh_x.handle, 'string');
            mesh_y = get(Custom_Mesh_y.handle, 'string');
            x_tok = regexp(mesh_x, '([0-9]+)', 'tokens');
            y_tok = regexp(mesh_y, '([0-9]+)', 'tokens');
            
            switch length(x_tok)
                case 1
                    x = str2double(x_tok{1});
                case 3
                    x = str2double(x_tok{1}) : str2double(x_tok{2}) : str2double(x_tok{3});
                otherwise
                    warning('Invalid custom mesh. Inputs for X and Y must be one or three numbers each, either [center] or [start:increment:end]')
                    return
            end
            switch length(y_tok)
                case 1
                    y = str2double(y_tok{1});
                case 3
                    y = str2double(y_tok{1}) : str2double(y_tok{2}) : str2double(y_tok{3});
                otherwise
                    warning('Invalid custom mesh. Inputs for X and Y must be one or three numbers each, either [center] or [start:increment:end]')
                    return
            end

            [X, Y] = meshgrid(x, y);
            
        else % default mesh
        
            mesh_qty = str2double(get(Mesh_Density.handle, 'string'));
            dp       = round(max(size(Image.RGB)) / mesh_qty); % px
            x        = round(dp/2 : dp : size(Image.RGB,2));
            y        = round(dp/2 : dp : size(Image.RGB,1));
            [X, Y]   = meshgrid(x, y);

            % Center X and Y
            margin_left   = min(X(:));
            margin_right  = size(Image.RGB,2)-max(X(:));
            margin_bottom = min(Y(:));
            margin_top    = size(Image.RGB,1)-max(Y(:));
            X             = X - round((margin_left-margin_right)/2);
            Y             = Y - round((margin_bottom-margin_top)/2);
        
        end % mesh created
        
        % Show mesh
        figure(7)
            set(gcf,'Name','Reconstructed Image and Sample Mesh','NumberTitle','off')
            clf
            set(gcf,'color','white')
            hold on
            image(Image.RGB)
            
            set(gca,'xtick',[])
            set(gca,'ytick',[])
            set(gca,'position',[0 0 1 1])
            
            axis equal
            axis tight
            set(gca,'YDir','reverse') % enforce standard directionality
            
            % Show the mesh and sample windows
            box_x = [1 1 -1 -1 1] / 2;
            box_y = [1 -1 -1 1 1] / 2;
            mesh_sample_window = str2double(get(Mesh_Sample_Window.handle, 'string')); % px, width of extraction region
            box_x = box_x .* mesh_sample_window;
            box_y = box_y .* mesh_sample_window;
            box_x = round(box_x);
            box_y = round(box_y);
            for i = 1 : numel(X)
                plot(X(i)+box_x, Y(i)+box_y, 'k')
                plot(X(i)+box_x, Y(i)+box_y, 'w:')
            end
        
        % Sample the HSDC
        REF_sample = [];
        SPD_sample = [];
        RGB_sample = [];
        mesh_sample_half_width = round(mesh_sample_window/2);
        for y_ind = 1 : size(X,1)
            for x_ind = 1 : size(X,2)
                y = (Y(y_ind,x_ind)-mesh_sample_half_width) : (Y(y_ind,x_ind)+mesh_sample_half_width);
                x = (X(y_ind,x_ind)-mesh_sample_half_width) : (X(y_ind,x_ind)+mesh_sample_half_width);
                spd = squeeze(HSDC(y,x,:));
                ref = squeeze(Reflectance(y,x,:));
                rgb = squeeze(Image.RGB(y,x,:));
                sample_qty = size(spd,1) * size(spd,2);
                SPD_sample(:,end+1) = sum(sum(spd,1),2) ./ sample_qty;
                REF_sample(:,end+1) = sum(sum(ref,1),2) ./ sample_qty;
                col = zeros(1,3);
                for cc = 1 : 3
                    swatch = rgb(:,:,cc);
                    col(1,cc) = mode(swatch(:));
                end
                RGB_sample(end+1,:) = col;
            end
        end
        assignin('base', 'SPD_sample', SPD_sample)
        assignin('base', 'REF_sample', REF_sample)
        assignin('base', 'RGB_sample', RGB_sample)

        if size(SPD_sample,2) == 24 % if checking the ColorChecker
            compare_SPDs(SPD_sample)
        end
            
        figure(8)
            set(gcf,'Name','SPDs and Colors at Sample Mesh','NumberTitle','off')
            clf
            set(gcf,'color','white')
            hold on
            for p = 1 : numel(X)
                plot(Observer.lambda,SPD_sample(:,p),'Color',RGB_sample(p,:),'LineWidth',2)
            end
            xlim(lambda_lims)
            ylim([0 max(ylim)])
            set(gca,'XTick',Filter.CWL)
            set(gca,'YTick',[])
            grid on
            xlabel('Wavelength, nm')
            ylabel('Spectral Power Distribution (HSDC), ~')
            title('SPDs and Colors at Sample Mesh')
            
        figure(9)
            set(gcf,'Name','Reflectances and Colors at Sample Mesh','NumberTitle','off')
            clf
            set(gcf,'color','white')
            hold on
            for p = 1 : numel(X)
                plot(Observer.lambda,REF_sample(:,p),'Color',RGB_sample(p,:),'LineWidth',2)
            end
            xlim(lambda_lims)
            ylim([0 max(ylim)])
            set(gca,'XTick',Filter.CWL)
            set(gca,'YTick',[])
            grid on
            xlabel('Wavelength, nm')
            ylabel('Reflectance, Relative, ~')
            title('Reflectances and Colors at Sample Mesh')
            
        switch Image.mode
            case 'preview'
                % Do nothing
            case 'export'
                timestamp = datestr(datetime('now'));
                timestamp = regexprep(timestamp,':','-');
                timestamp = regexprep(timestamp,' ','_');
                
                fn_export = [
                                regexprep(Photo.filename_first,'\..+','') '_' ...
                                'spectral_'...
                                num2str(max(size(Image.RGB))) '_px_'...
                                timestamp...
                            ];
                        
                imwrite(Image.RGB, [Photo.pathdir '\' fn_export '.jpg'], 'Quality', 100)
        end

        % Send structures to workspace
        assignin('base','Wavelength', Wavelength)
        assignin('base','Observer',   Observer)
        assignin('base','Photo',      Photo)
        assignin('base','Filter',     Filter)
        assignin('base','Image',      Image)
        assignin('base','Camera',     Camera)
        assignin('base','Sensor',     Sensor)
        assignin('base','HSDC',       HSDC)

    end

    %%

    function load_photos
        
        [Photo.filename_first, Photo.pathdir] = uigetfile('*.*','Select the first photo in the stack, corresponding to the first filter');
        
        if ~Photo.filename_first
            warning('No photos loaded')
            return
        end
        
        % Generate sequential filenames for photo stack
        Photo.filenames = cell(Filter.qty, 1);
        Photo.extension = regexprep(Photo.filename_first, '[^\.]+\.','');
        fn_without_extension = regexprep(Photo.filename_first, Photo.extension, '');
        Photo.base_num = str2double(regexprep(fn_without_extension, '[^0-9]+', ''));
        Photo.prefix = regexprep(Photo.filename_first, '[0-9]+.+','');
        Photo.filenames{1} = Photo.filename_first;
        for f = 2 : Filter.qty
            Photo.filenames{f} = [Photo.prefix num2str(Photo.base_num-1+f) '.' Photo.extension];
        end

        tic
        h = waitbar(0,'');

        Photo.qty = length(Photo.filenames);
        Photo.RGB_calc    = cell(Photo.qty, 1); % for HSDC calculation

        % Load data from files
        for p = 1 : Photo.qty

            % Update waitbar
            status = p / (Photo.qty+1);
            waitbar(status,h,['Loading ' regexprep(Photo.filenames{p},'\_','\\_') '...'])
            
            [~, RGB_calc, ~] = extract_RAW_via_dcraw(Photo.pathdir, Photo.filenames{p}, 'rggb', '-D -4 -j -t 0', 0, 0, 0);

            % Apply black offset
            RGB_calc = RGB_calc - Photo.RAW_black_level;
            
            if p == 1 % First image in the stack sets the standard width and height
                Photo.res_orig = [size(RGB_calc,1), size(RGB_calc,2)];
            end
            
            Photo.RGB_calc{p} = RGB_calc;

        end

        close(h)
                    
        figure(5)
            clf
            hold on
            set(gcf,'color','white')
            set(gcf,'Name','Photo Histograms','NumberTitle','off')
            
            bit_depth = 14;
            centers = 0 : (2^bit_depth-1);
            edges = -0.5 : (2^bit_depth-0.5);
            
            for p = 1 : Photo.qty
                
                for cc = 1 : 3
                    counts = histcounts(Photo.RGB_calc{p}(:,:,cc), edges);
                    col = [0 0 0];
                    col(cc) = 1;
                    plot(centers + Photo.RAW_black_level, counts, 'Color', col)
                end
                
            end
            
        xlabel('RAW Value, ~')
        ylabel('Quantity of Pixels, ~')
        xlim([0 max(edges)])
        grid on
        grid minor
        set(gca, 'yscale', 'log')
            
        reset_figures

    end

    %%

    function update_filters
        
        i_fil = get(Select_Filters.handle, 'value');
        Filter.description = Select_Filters.vals{i_fil};
        
        switch i_fil
            
            case 1 % ThorLabs Qty. 7 CWL 420:40:660 FWHM 10
                % Source: https://www.thorlabs.com/newgrouppage9.cfm?objectgroup_id=1001
                Filter.lambda = 400 : 700;
                trans = [2.21000000000000e-05,2.98000000000000e-05,4.07000000000000e-05,5.89000000000000e-05,8.68000000000000e-05,0.000131200000000000,0.000203800000000000,0.000324000000000000,0.000534800000000000,0.000916700000000000,0.00163890000000000,0.00309110000000000,0.00623500000000000,0.0136615000000000,0.0324912000000000,0.0785535000000000,0.172248800000000,0.296812600000000,0.398243600000000,0.446206300000000,0.459848100000000,0.464594000000000,0.466664900000000,0.460771800000000,0.430465000000000,0.353831500000000,0.238815200000000,0.131262100000000,0.0632231000000000,0.0293616000000000,0.0144699000000000,0.00768930000000000,0.00435370000000000,0.00262290000000000,0.00165980000000000,0.00109390000000000,0.000750500000000000,0.000528400000000000,0.000383100000000000,0.000285000000000000,0.000217000000000000,0.000168500000000000,0.000133600000000000,0.000107700000000000,8.78000000000000e-05,7.27000000000000e-05,6.07000000000000e-05,5.18000000000000e-05,4.41000000000000e-05,3.82000000000000e-05,3.30000000000000e-05,2.88000000000000e-05,2.52000000000000e-05,2.21000000000000e-05,1.91000000000000e-05,1.69000000000000e-05,1.47000000000000e-05,1.28000000000000e-05,1.09000000000000e-05,9.39073000000000e-06,7.82692000000000e-06,6.46631000000000e-06,5.30541000000000e-06,4.31324000000000e-06,3.41719000000000e-06,2.76791000000000e-06,2.18426000000000e-06,1.74204000000000e-06,1.30541000000000e-06,9.96426000000000e-07,8.40049000000000e-07,6.75697000000000e-07,6.67512000000000e-07,3.89520000000000e-07,3.22122000000000e-07,3.30175000000000e-07,2.79410000000000e-07,2.02608000000000e-07,2.01289000000000e-07,8.84422000000000e-08,1.26780000000000e-07,3.34598000000000e-08,1.08271000000000e-07,2.75169000000000e-08,1.47191000000000e-08,3.91010000000000e-08,6.92919000000000e-08,3.21909000000000e-08,8.08530000000000e-08,4.61416000000000e-08,2.05703000000000e-08,2.86560000000000e-09,3.64677000000000e-08,4.22954000000000e-08,4.79363000000000e-08,7.42813000000000e-08,3.49286000000000e-08,4.85940000000000e-08,1.79683000000000e-08,1.47372000000000e-08,2.23314000000000e-08,9.75664000000000e-08,4.04398000000000e-08,8.09969000000000e-08,3.57951000000000e-08,6.45438000000000e-08,2.25838000000000e-07,9.69028000000000e-10,4.19517000000000e-08,3.14931000000000e-08,1.86060000000000e-08,1.50359000000000e-08,2.90056000000000e-08,2.07900000000000e-08,6.58814000000000e-08,2.09268000000000e-08,3.84710000000000e-08,5.77587000000000e-08,1.18365000000000e-08,1.21130000000000e-07,1.11171000000000e-07,2.48292000000000e-08,5.64341000000000e-08,4.89572000000000e-08,1.64511000000000e-07,1.39890000000000e-07,1.12905000000000e-07,1.75333000000000e-07,1.60846000000000e-07,3.36982000000000e-07,4.30853000000000e-07,4.80584000000000e-07,6.39672000000000e-07,7.19533000000000e-07,8.27276000000000e-07,9.87276000000000e-07,1.14085000000000e-06,1.08723000000000e-06,1.01654000000000e-06,1.01211000000000e-06,8.88743000000000e-07,7.85382000000000e-07,8.01450000000000e-07,6.64915000000000e-07,5.98281000000000e-07,6.58727000000000e-07,5.75165000000000e-07,5.62469000000000e-07,5.63702000000000e-07,4.88017000000000e-07,5.07321000000000e-07,6.32392000000000e-07,4.56881000000000e-07,5.24140000000000e-07,4.18093000000000e-07,4.04769000000000e-07,3.89481000000000e-07,4.35647000000000e-07,5.20002000000000e-07,4.50243000000000e-07,3.30136000000000e-07,4.28404000000000e-07,4.09574000000000e-07,4.03846000000000e-07,3.84441000000000e-07,3.45414000000000e-07,4.26489000000000e-07,3.30230000000000e-07,5.13962000000000e-07,3.64004000000000e-07,1.91183000000000e-07,3.68529000000000e-07,3.88422000000000e-07,2.63713000000000e-07,3.63659000000000e-07,3.46040000000000e-07,3.39948000000000e-07,1.60294000000000e-07,3.25194000000000e-07,3.89460000000000e-07,2.66250000000000e-07,3.08836000000000e-07,1.66108000000000e-07,2.86201000000000e-07,2.92749000000000e-07,3.61762000000000e-07,1.81554000000000e-07,3.86045000000000e-07,3.18256000000000e-07,2.06445000000000e-07,3.70438000000000e-07,3.86025000000000e-07,2.51378000000000e-07,4.30886000000000e-07,4.23523000000000e-07,3.55561000000000e-07,3.74872000000000e-07,3.14677000000000e-07,4.72178000000000e-07,4.28798000000000e-07,3.76364000000000e-07,5.48958000000000e-07,4.42382000000000e-07,5.17914000000000e-07,5.80243000000000e-07,7.46196000000000e-07,6.19891000000000e-07,6.63146000000000e-07,8.35288000000000e-07,8.50810000000000e-07,9.36175000000000e-07,1.00706000000000e-06,1.05346000000000e-06,1.22626000000000e-06,1.34275000000000e-06,1.66207000000000e-06,1.83125000000000e-06,2.04209000000000e-06,2.36565000000000e-06,2.81151000000000e-06,3.17754000000000e-06,3.74624000000000e-06,4.26692000000000e-06,4.90167000000000e-06,5.32740000000000e-06,5.53764000000000e-06,5.41749000000000e-06,4.94108000000000e-06,4.43876000000000e-06,3.60135000000000e-06,2.97082000000000e-06,2.40839000000000e-06,1.99871000000000e-06,1.59855000000000e-06,1.32186000000000e-06,1.05588000000000e-06,7.23383000000000e-07,7.13933000000000e-07,5.61107000000000e-07,5.06875000000000e-07,4.66548000000000e-07,3.66491000000000e-07,2.97419000000000e-07,1.42805000000000e-07,2.17747000000000e-07,2.38276000000000e-07,1.79728000000000e-07,2.40603000000000e-07,1.26927000000000e-07,1.72766000000000e-07,1.02187000000000e-07,1.07387000000000e-07,7.60186000000000e-08,7.96176000000000e-08,1.00563000000000e-08,1.12674000000000e-07,6.25546000000000e-08,8.95008000000000e-08,3.50961000000000e-08,3.64649000000000e-08,8.43364000000000e-08,7.35831000000000e-08,1.04313000000000e-07,6.38197000000000e-08,7.92807000000000e-08,1.27499000000000e-07,2.13633000000000e-08,2.44218000000000e-09,7.79074000000000e-08,1.44022000000000e-08,1.91008000000000e-07,4.75540000000000e-08,1.07381000000000e-07,3.83294000000000e-08,8.43420000000000e-08,2.35422000000000e-08,1.28660000000000e-08,1.90962000000000e-08,1.73666000000000e-07,5.21983000000000e-08,6.58180000000000e-08,7.21989000000000e-08,2.22302000000000e-08,2.90398000000000e-08,6.80881000000000e-08,1.08733000000000e-08,3.55680000000000e-09,3.19897000000000e-10,1.38990000000000e-07,1.82840000000000e-08,6.42646000000000e-08,3.79448000000000e-08,4.78746000000000e-08,6.10201000000000e-09,1.45120000000000e-07,7.95888000000000e-08,5.25488000000000e-08,5.95137000000000e-08,5.22600000000000e-08,9.30844000000000e-09,5.31344000000000e-08;1.32519000000000e-07,9.68735000000000e-08,5.27532000000000e-08,1.20221000000000e-07,2.03264000000000e-07,1.11613000000000e-07,1.54213000000000e-07,1.54790000000000e-07,1.11477000000000e-07,2.72904000000000e-07,2.31616000000000e-07,9.12712000000000e-08,4.42560000000000e-07,4.40121000000000e-07,6.40576000000000e-07,6.08434000000000e-07,1.02159000000000e-06,1.42689000000000e-06,2.00303000000000e-06,2.65362000000000e-06,3.87672000000000e-06,5.28067000000000e-06,6.75513000000000e-06,8.61403000000000e-06,1.06000000000000e-05,1.23000000000000e-05,1.45000000000000e-05,1.67000000000000e-05,1.94000000000000e-05,2.23000000000000e-05,2.64000000000000e-05,3.06000000000000e-05,3.60000000000000e-05,4.28000000000000e-05,5.18000000000000e-05,6.29000000000000e-05,7.71000000000000e-05,9.67000000000000e-05,0.000123100000000000,0.000159300000000000,0.000211500000000000,0.000285900000000000,0.000398700000000000,0.000570500000000000,0.000836800000000000,0.00128250000000000,0.00203380000000000,0.00336840000000000,0.00586120000000000,0.0106956000000000,0.0207026000000000,0.0415495000000000,0.0824256000000000,0.152174000000000,0.246987400000000,0.346481400000000,0.429402800000000,0.491058400000000,0.537131200000000,0.562729000000000,0.560809300000000,0.526506000000000,0.459293700000000,0.363517500000000,0.254775400000000,0.157262400000000,0.0810770000000000,0.0450252000000000,0.0236363000000000,0.0129891000000000,0.00755270000000000,0.00456950000000000,0.00289830000000000,0.00192040000000000,0.00131060000000000,0.000924600000000000,0.000670300000000000,0.000498400000000000,0.000380400000000000,0.000294600000000000,0.000233900000000000,0.000188400000000000,0.000155200000000000,0.000129200000000000,0.000109100000000000,9.37000000000000e-05,8.14000000000000e-05,7.12000000000000e-05,6.32000000000000e-05,5.67000000000000e-05,5.13000000000000e-05,4.70000000000000e-05,4.28000000000000e-05,4.01000000000000e-05,3.76000000000000e-05,3.53000000000000e-05,3.36000000000000e-05,3.19000000000000e-05,3.07000000000000e-05,2.95000000000000e-05,2.85000000000000e-05,2.72000000000000e-05,2.58000000000000e-05,2.42000000000000e-05,2.25000000000000e-05,2.01000000000000e-05,1.82000000000000e-05,1.57000000000000e-05,1.32000000000000e-05,1.09000000000000e-05,8.77965000000000e-06,7.09216000000000e-06,5.60360000000000e-06,4.30567000000000e-06,3.48760000000000e-06,2.71323000000000e-06,2.07951000000000e-06,1.75171000000000e-06,1.33431000000000e-06,1.00014000000000e-06,8.27554000000000e-07,7.85381000000000e-07,5.75663000000000e-07,4.44493000000000e-07,3.59425000000000e-07,3.12068000000000e-07,3.15305000000000e-07,2.44900000000000e-07,1.42578000000000e-07,1.64712000000000e-07,1.40788000000000e-07,1.28619000000000e-07,1.42000000000000e-07,6.83090000000000e-08,4.76190000000000e-08,9.29127000000000e-08,2.09375000000000e-07,9.07012000000000e-08,5.08132000000000e-08,1.43703000000000e-07,1.10781000000000e-07,7.16378000000000e-08,2.89424000000000e-08,8.95953000000000e-08,3.38357000000000e-08,6.22928000000000e-08,1.07864000000000e-07,1.13299000000000e-07,1.25365000000000e-07,1.59364000000000e-07,6.98623000000000e-09,8.31647000000000e-08,2.54674000000000e-08,5.41863000000000e-08,7.38865000000000e-08,8.13181000000000e-08,1.05306000000000e-07,1.02178000000000e-07,1.00102000000000e-07,1.26121000000000e-07,5.81436000000000e-08,2.05267000000000e-07,2.12838000000000e-07,2.39723000000000e-07,2.62541000000000e-07,2.02540000000000e-07,3.64394000000000e-07,4.55715000000000e-07,7.94191000000000e-07,8.05031000000000e-07,1.05399000000000e-06,1.72315000000000e-06,2.11911000000000e-06,2.25905000000000e-06,2.33154000000000e-06,1.94490000000000e-06,1.57591000000000e-06,1.03790000000000e-06,9.37816000000000e-07,7.06222000000000e-07,4.95446000000000e-07,4.45379000000000e-07,3.61999000000000e-07,1.38314000000000e-07,2.93606000000000e-07,2.85927000000000e-07,6.78435000000000e-08,1.50359000000000e-07,1.23820000000000e-07,3.66175000000000e-08,2.46236000000000e-07,1.60994000000000e-07,2.15431000000000e-08,1.60163000000000e-07,1.90357000000000e-07,7.45029000000000e-09,1.49551000000000e-07,2.01809000000000e-08,1.53105000000000e-07,7.09557000000000e-08,7.91870000000000e-08,8.10906000000000e-08,2.06922000000000e-08,1.60384000000000e-07,1.21210000000000e-07,2.15329000000000e-07,5.50988000000000e-08,8.34507000000000e-08,2.01543000000000e-07,1.37781000000000e-07,6.55547000000000e-08,1.34459000000000e-07,9.32683000000000e-08,7.33681000000000e-08,1.39189000000000e-07,2.27571000000000e-07,8.26262000000000e-08,3.98630000000000e-08,6.97255000000000e-08,1.67707000000000e-07,6.24939000000000e-08,1.06759000000000e-08,2.86457000000000e-08,6.44031000000000e-08,3.86876000000000e-08,6.24898000000000e-08,1.59416000000000e-08,6.87167000000000e-09,1.67106000000000e-08,5.14414000000000e-08,4.66926000000000e-08,6.61626000000000e-08,6.99930000000000e-08,2.73044000000000e-08,3.40922000000000e-08,1.36899000000000e-08,1.03898000000000e-07,3.47447000000000e-08,8.50037000000000e-08,3.04913000000000e-08,6.12374000000000e-09,1.63100000000000e-08,5.89955000000000e-08,1.23240000000000e-07,2.79955000000000e-08,1.54716000000000e-08,1.09928000000000e-07,3.20621000000000e-08,2.38190000000000e-08,1.94528000000000e-08,5.23629000000000e-09,6.19100000000000e-08,6.40803000000000e-08,3.51040000000000e-08,1.87983000000000e-09,1.75897000000000e-08,2.12522000000000e-08,6.67588000000000e-08,5.74410000000000e-09,3.72808000000000e-08,2.23602000000000e-09,7.41440000000000e-08,1.20601000000000e-08,7.47888000000000e-09,4.31392000000000e-08,9.45541000000000e-08,7.15866000000000e-09,1.10342000000000e-08,3.69569000000000e-08,2.54424000000000e-08,5.62994000000000e-08,2.29323000000000e-08,2.83139000000000e-08,2.47380000000000e-08,1.25890000000000e-07,2.38663000000000e-08,1.53136000000000e-08,1.06723000000000e-08,6.72500000000000e-08,1.64584000000000e-08,1.12954000000000e-08,1.50011000000000e-07,4.79684000000000e-08,3.27102000000000e-09,6.95343000000000e-08,7.21246000000000e-10,2.24003000000000e-09,3.08615000000000e-08,1.33983000000000e-07,4.51697000000000e-08,5.71993000000000e-09,1.63399000000000e-07,3.27635000000000e-08,3.71415000000000e-08,9.62415000000000e-08,5.99955000000000e-08,3.77846000000000e-08,1.07133000000000e-07,8.72827000000000e-08,4.07232000000000e-08,4.26948000000000e-08;8.25440000000000e-06,7.71878000000000e-06,7.38498000000000e-06,7.63726000000000e-06,8.39454000000000e-06,9.49296000000000e-06,1.14000000000000e-05,1.38000000000000e-05,1.67000000000000e-05,1.90000000000000e-05,1.95000000000000e-05,1.79000000000000e-05,1.60000000000000e-05,1.39000000000000e-05,1.25000000000000e-05,1.22000000000000e-05,1.34000000000000e-05,1.72000000000000e-05,2.49000000000000e-05,3.50000000000000e-05,3.63000000000000e-05,2.52000000000000e-05,1.22000000000000e-05,5.07109000000000e-06,2.55225000000000e-06,1.36401000000000e-06,9.08997000000000e-07,5.62080000000000e-07,4.59433000000000e-07,1.79843000000000e-07,3.03923000000000e-07,2.11326000000000e-07,1.77427000000000e-07,1.04793000000000e-07,1.97620000000000e-07,1.70135000000000e-07,1.26322000000000e-07,1.35704000000000e-07,1.09676000000000e-07,2.02748000000000e-07,2.12420000000000e-07,1.24320000000000e-07,8.76778000000000e-08,4.70050000000000e-08,8.13336000000000e-08,6.28846000000000e-08,2.29344000000000e-07,9.49326000000000e-08,1.35614000000000e-07,1.70252000000000e-07,9.49133000000000e-08,1.98529000000000e-07,1.31297000000000e-07,2.17013000000000e-08,1.83654000000000e-07,1.91341000000000e-07,2.87801000000000e-07,2.64384000000000e-07,1.91403000000000e-07,3.05821000000000e-07,2.56379000000000e-07,3.43562000000000e-07,4.76382000000000e-07,4.67901000000000e-07,6.67089000000000e-07,6.16006000000000e-07,9.00844000000000e-07,1.14160000000000e-06,1.36360000000000e-06,1.72270000000000e-06,2.17215000000000e-06,2.72240000000000e-06,3.65322000000000e-06,4.60744000000000e-06,5.90388000000000e-06,7.92153000000000e-06,2.32400000000000e-05,2.53500000000000e-05,3.27400000000000e-05,7.60600000000000e-05,9.39800000000000e-05,0.000123490000000000,0.000241680000000000,0.000333500000000000,0.000523460000000000,0.000807620000000000,0.00127940000000000,0.00206805000000000,0.00360045000000000,0.00640946000000000,0.0124271000000000,0.0241520900000000,0.0484719000000000,0.0974299100000000,0.179457090000000,0.287493160000000,0.389686360000000,0.456287960000000,0.488112880000000,0.500050700000000,0.500228460000000,0.489473820000000,0.465439310000000,0.419903440000000,0.343305310000000,0.242873920000000,0.145857750000000,0.0778225900000000,0.0394893400000000,0.0204859400000000,0.0112261700000000,0.00617960000000000,0.00370304000000000,0.00231982000000000,0.00146126000000000,0.000995310000000000,0.000621440000000000,0.000455610000000000,0.000316400000000000,0.000237280000000000,0.000133910000000000,0.000105490000000000,3.69100000000000e-05,6.32500000000000e-05,2.10800000000000e-05,1.89700000000000e-05,1.15000000000000e-05,9.41670000000000e-06,7.80358000000000e-06,6.48056000000000e-06,5.49119000000000e-06,4.44745000000000e-06,3.96568000000000e-06,3.21598000000000e-06,2.77735000000000e-06,2.37636000000000e-06,2.05477000000000e-06,1.79761000000000e-06,1.39479000000000e-06,1.19707000000000e-06,1.06467000000000e-06,8.67553000000000e-07,7.32059000000000e-07,6.49027000000000e-07,6.13493000000000e-07,5.80720000000000e-07,4.62681000000000e-07,3.57792000000000e-07,3.73858000000000e-07,2.90061000000000e-07,2.23899000000000e-07,2.10622000000000e-07,1.50710000000000e-07,1.84845000000000e-07,1.97023000000000e-07,1.81133000000000e-07,1.67910000000000e-07,1.19454000000000e-07,1.60728000000000e-07,1.18029000000000e-07,1.53203000000000e-07,1.85258000000000e-07,1.38427000000000e-07,4.58816000000000e-08,6.07563000000000e-08,1.50220000000000e-07,1.41005000000000e-07,1.05145000000000e-08,1.29258000000000e-07,2.96833000000000e-08,5.70713000000000e-08,7.06634000000000e-08,1.08631000000000e-07,5.03078000000000e-08,1.11714000000000e-07,2.85650000000000e-08,4.08274000000000e-08,1.07728000000000e-07,1.78417000000000e-08,1.20799000000000e-07,5.44811000000000e-08,7.51771000000000e-08,7.62948000000000e-08,8.25019000000000e-09,1.89439000000000e-07,1.32929000000000e-07,7.06633000000000e-08,9.44174000000000e-08,5.01253000000000e-08,7.76524000000000e-08,1.45874000000000e-08,2.39090000000000e-10,8.01043000000000e-08,7.99418000000000e-08,1.17841000000000e-08,7.63786000000000e-08,8.19833000000000e-08,7.06348000000000e-08,6.13402000000000e-08,9.89444000000000e-08,7.51821000000000e-08,1.12286000000000e-07,3.76751000000000e-09,9.09182000000000e-08,6.09027000000000e-08,7.61029000000000e-08,2.79187000000000e-08,2.35396000000000e-08,8.10931000000000e-08,3.33054000000000e-08,7.47391000000000e-08,5.14032000000000e-09,8.43462000000000e-08,7.54489000000000e-08,4.09350000000000e-08,2.09785000000000e-07,1.30262000000000e-08,5.10047000000000e-08,6.65896000000000e-08,4.93723000000000e-08,1.80275000000000e-07,5.69523000000000e-08,2.64979000000000e-09,7.96112000000000e-08,8.47812000000000e-09,6.40228000000000e-08,1.00951000000000e-07,2.51738000000000e-08,7.66084000000000e-08,7.60585000000000e-08,7.78685000000000e-08,1.71361000000000e-07,5.00843000000000e-08,1.54228000000000e-07,1.26486000000000e-07,1.78372000000000e-07,2.79712000000000e-07,2.00473000000000e-07,1.92585000000000e-07,3.20683000000000e-07,1.98704000000000e-07,1.93798000000000e-07,6.18389000000000e-08,6.38138000000000e-08,1.93743000000000e-07,8.72895000000000e-08,1.39997000000000e-07,1.26521000000000e-07,9.54250000000000e-08,1.13875000000000e-07,4.63201000000000e-08,2.12126000000000e-08,1.28109000000000e-07,3.20902000000000e-08,6.17872000000000e-08,3.05742000000000e-09,5.61922000000000e-08,5.12276000000000e-10,8.84077000000000e-08,6.75028000000000e-08,4.44987000000000e-08,2.37031000000000e-08,6.96470000000000e-08,8.97236000000000e-08,4.59912000000000e-08,1.06934000000000e-07,1.46866000000000e-07,5.86296000000000e-08,3.01919000000000e-08,8.31564000000000e-08,1.38286000000000e-07,9.48066000000000e-09,2.29110000000000e-08,1.37506000000000e-07,6.95183000000000e-08,1.96846000000000e-07,5.37979000000000e-08,2.62443000000000e-08,2.17139000000000e-07,1.29611000000000e-08,1.01409000000000e-07,7.14053000000000e-08,1.99708000000000e-07,6.52817000000000e-08,3.27498000000000e-08,1.45251000000000e-07,5.18816000000000e-08,3.08198000000000e-08,1.81639000000000e-07,8.66641000000000e-08,1.64827000000000e-08,2.03254000000000e-07,3.70624000000000e-09,6.09671000000000e-08,1.11411000000000e-07,1.60521000000000e-07,2.82621000000000e-08,6.77459000000000e-08,2.07364000000000e-07,3.53817000000000e-08,3.34794000000000e-08;0.000335100000000000,0.000301200000000000,0.000270500000000000,0.000242500000000000,0.000218800000000000,0.000197200000000000,0.000178800000000000,0.000161700000000000,0.000148800000000000,0.000136600000000000,0.000129000000000000,0.000122200000000000,0.000118300000000000,0.000115200000000000,0.000115400000000000,0.000115500000000000,0.000115400000000000,0.000114000000000000,0.000109400000000000,0.000101700000000000,9.20000000000000e-05,8.11000000000000e-05,6.98000000000000e-05,5.99000000000000e-05,5.25000000000000e-05,4.63000000000000e-05,4.25000000000000e-05,3.99000000000000e-05,3.92000000000000e-05,3.91000000000000e-05,3.99000000000000e-05,4.04000000000000e-05,4.01000000000000e-05,3.78000000000000e-05,3.34000000000000e-05,2.77000000000000e-05,2.19000000000000e-05,1.74000000000000e-05,1.33000000000000e-05,1.09000000000000e-05,8.92235000000000e-06,7.86337000000000e-06,7.27124000000000e-06,7.02258000000000e-06,7.19869000000000e-06,8.05426000000000e-06,1.02000000000000e-05,1.52000000000000e-05,2.66000000000000e-05,4.30000000000000e-05,4.87000000000000e-05,3.44000000000000e-05,1.57000000000000e-05,6.12135000000000e-06,3.03883000000000e-06,1.61918000000000e-06,1.08964000000000e-06,7.01913000000000e-07,4.42846000000000e-07,4.38211000000000e-07,3.06906000000000e-07,1.87406000000000e-07,2.75692000000000e-07,1.53769000000000e-07,2.57158000000000e-07,1.03202000000000e-07,1.53499000000000e-07,2.23344000000000e-07,9.01169000000000e-08,1.02278000000000e-07,3.14040000000000e-08,8.11734000000000e-08,1.48707000000000e-07,1.39641000000000e-07,6.27657000000000e-08,1.86745000000000e-07,9.12414000000000e-08,1.75803000000000e-07,3.19830000000000e-08,3.39530000000000e-08,1.63263000000000e-07,1.17590000000000e-07,6.37580000000000e-08,8.61546000000000e-08,8.65095000000000e-08,1.54727000000000e-07,6.32976000000000e-08,1.08148000000000e-07,1.75607000000000e-07,1.27101000000000e-07,1.70471000000000e-07,1.64389000000000e-07,2.18320000000000e-07,1.97713000000000e-07,1.98658000000000e-07,2.18836000000000e-07,3.01194000000000e-07,4.17136000000000e-07,4.78094000000000e-07,4.33200000000000e-07,4.69083000000000e-07,6.70741000000000e-07,7.52608000000000e-07,9.52326000000000e-07,1.11379000000000e-06,1.45813000000000e-06,1.87577000000000e-06,2.26867000000000e-06,2.89083000000000e-06,3.82016000000000e-06,5.05463000000000e-06,6.51062000000000e-06,8.78799000000000e-06,1.18000000000000e-05,1.58000000000000e-05,2.15000000000000e-05,2.95000000000000e-05,4.07000000000000e-05,5.67000000000000e-05,7.98000000000000e-05,0.000114300000000000,0.000164700000000000,0.000242100000000000,0.000363900000000000,0.000557400000000000,0.000871700000000000,0.00141530000000000,0.00237560000000000,0.00417620000000000,0.00764650000000000,0.0148830000000000,0.0311347000000000,0.0683101000000000,0.146210100000000,0.273052500000000,0.417522000000000,0.523739500000000,0.569553700000000,0.576882200000000,0.568575800000000,0.553457300000000,0.526931000000000,0.470881300000000,0.371038800000000,0.243378200000000,0.133147700000000,0.0652275000000000,0.0313597000000000,0.0157161000000000,0.00836700000000000,0.00474220000000000,0.00283200000000000,0.00174870000000000,0.00112670000000000,0.000747500000000000,0.000507900000000000,0.000356300000000000,0.000255600000000000,0.000187000000000000,0.000140100000000000,0.000106000000000000,8.16000000000000e-05,6.38000000000000e-05,5.03000000000000e-05,4.02000000000000e-05,3.24000000000000e-05,2.66000000000000e-05,2.15000000000000e-05,1.81000000000000e-05,1.50000000000000e-05,1.28000000000000e-05,1.09000000000000e-05,9.31451000000000e-06,8.14544000000000e-06,7.06779000000000e-06,6.10959000000000e-06,5.32662000000000e-06,4.74711000000000e-06,4.20688000000000e-06,3.91695000000000e-06,3.41862000000000e-06,3.01327000000000e-06,2.72138000000000e-06,2.47106000000000e-06,2.38301000000000e-06,2.00919000000000e-06,1.66555000000000e-06,1.76138000000000e-06,1.53801000000000e-06,1.27842000000000e-06,1.30299000000000e-06,1.09475000000000e-06,1.05305000000000e-06,1.01742000000000e-06,8.28450000000000e-07,7.50773000000000e-07,7.14086000000000e-07,6.13151000000000e-07,5.93743000000000e-07,4.09220000000000e-07,4.80290000000000e-07,4.68909000000000e-07,4.02930000000000e-07,3.01819000000000e-07,2.55219000000000e-07,3.60626000000000e-07,2.16012000000000e-07,2.43341000000000e-07,2.31473000000000e-07,1.13665000000000e-07,1.87249000000000e-07,1.73213000000000e-07,1.38035000000000e-07,2.20282000000000e-07,1.22113000000000e-07,2.02670000000000e-07,6.35637000000000e-08,4.93192000000000e-09,1.34023000000000e-07,5.70260000000000e-08,1.60291000000000e-07,1.25197000000000e-07,4.96665000000000e-08,1.04227000000000e-07,5.22792000000000e-09,9.42783000000000e-08,6.47904000000000e-08,2.82331000000000e-08,6.73882000000000e-08,1.54468000000000e-08,3.23560000000000e-08,6.31426000000000e-08,6.95455000000000e-09,4.57724000000000e-08,1.62978000000000e-07,8.31210000000000e-09,6.18781000000000e-08,1.04600000000000e-07,1.04486000000000e-08,1.11023000000000e-07,5.00406000000000e-09,8.80561000000000e-08,5.05673000000000e-08,1.31880000000000e-07,1.51068000000000e-07,1.39866000000000e-08,5.30855000000000e-09,1.28532000000000e-07,4.60879000000000e-08,5.77434000000000e-08,1.51543000000000e-08,6.86088000000000e-10,3.87609000000000e-08,2.64698000000000e-08,1.33986000000000e-07,1.52446000000000e-08,1.62863000000000e-08,9.08075000000000e-08,8.49934000000000e-08,1.69894000000000e-08,4.05704000000000e-09,2.09602000000000e-08,3.00990000000000e-08,1.43058000000000e-08,7.32856000000000e-09,4.01655000000000e-08,1.47820000000000e-07,3.77267000000000e-08,4.56308000000000e-08,2.55472000000000e-08,1.72082000000000e-07,5.03419000000000e-08,7.64137000000000e-08,3.20220000000000e-08,1.64951000000000e-07,6.21910000000000e-08,7.78342000000000e-08,2.89835000000000e-08,1.27228000000000e-07,2.66096000000000e-09,7.00784000000000e-08,3.70283000000000e-08,1.64323000000000e-07,4.45264000000000e-08,2.33814000000000e-08,1.69444000000000e-07,3.60606000000000e-08,1.13191000000000e-08,1.76415000000000e-07,5.14608000000000e-08,8.83094000000000e-08,1.16154000000000e-07,3.04574000000000e-08,1.05794000000000e-08,4.02535000000000e-08,1.30128000000000e-07,8.56497000000000e-08,1.34308000000000e-08,1.83961000000000e-07,4.37082000000000e-08,3.25727000000000e-08;1.27405000000000e-07,6.61373000000000e-08,1.05168000000000e-07,9.40834000000000e-08,6.19679000000000e-08,1.18221000000000e-07,5.16625000000000e-08,1.18323000000000e-07,6.30805000000000e-08,7.41808000000000e-08,6.43883000000000e-08,7.28618000000000e-08,1.19762000000000e-07,1.25872000000000e-08,9.85668000000000e-08,7.90059000000000e-08,4.90435000000000e-08,9.00969000000000e-08,5.29221000000000e-08,8.24978000000000e-08,1.31001000000000e-07,4.84195000000000e-08,6.69275000000000e-08,8.42424000000000e-09,2.51185000000000e-08,5.95209000000000e-08,1.26200000000000e-07,4.20524000000000e-08,3.93038000000000e-09,1.90472000000000e-08,1.80202000000000e-07,8.66406000000000e-08,1.68107000000000e-08,3.61468000000000e-08,5.15949000000000e-08,2.12254000000000e-07,5.57809000000000e-08,9.01386000000000e-09,6.70873000000000e-08,1.45059000000000e-07,8.41764000000000e-08,1.22094000000000e-07,9.18331000000000e-08,5.82698000000000e-08,5.94915000000000e-08,1.23349000000000e-08,1.12876000000000e-07,1.23419000000000e-07,1.36698000000000e-07,8.07327000000000e-08,5.06434000000000e-08,2.91926000000000e-08,6.87706000000000e-08,8.16559000000000e-08,6.05935000000000e-08,9.55258000000000e-08,5.24078000000000e-08,9.68213000000000e-08,9.52213000000000e-08,1.68256000000000e-07,2.06082000000000e-07,1.73587000000000e-07,1.97860000000000e-07,8.15569000000000e-08,1.15059000000000e-07,1.65407000000000e-07,1.34783000000000e-07,1.84360000000000e-07,1.35440000000000e-07,2.94779000000000e-07,2.70919000000000e-07,1.62770000000000e-07,1.22791000000000e-07,1.28819000000000e-07,2.41604000000000e-07,2.06009000000000e-07,2.07334000000000e-07,3.31648000000000e-07,3.07199000000000e-07,2.90546000000000e-07,1.73345000000000e-07,1.04928000000000e-07,4.83951000000000e-08,7.79915000000000e-08,3.89457000000000e-08,9.26042000000000e-08,4.15864000000000e-08,4.74629000000000e-08,2.39381000000000e-08,6.63961000000000e-08,2.80312000000000e-08,1.65807000000000e-08,4.44255000000000e-08,3.09835000000000e-08,6.49618000000000e-08,7.37612000000000e-08,2.36262000000000e-08,2.36126000000000e-10,3.01086000000000e-08,3.74743000000000e-08,1.93782000000000e-08,1.62967000000000e-07,5.73924000000000e-08,4.60859000000000e-09,5.76888000000000e-08,1.09558000000000e-08,3.51588000000000e-09,4.80678000000000e-09,2.79073000000000e-10,4.14473000000000e-08,5.39678000000000e-08,7.83593000000000e-08,2.66125000000000e-08,6.02783000000000e-08,6.38653000000000e-08,1.99945000000000e-08,2.28495000000000e-08,3.22931000000000e-08,1.40982000000000e-08,5.03651000000000e-08,6.42675000000000e-08,2.17846000000000e-09,1.61269000000000e-08,2.05689000000000e-08,6.71145000000000e-08,7.80082000000000e-09,5.33068000000000e-08,6.75151000000000e-09,2.72832000000000e-09,2.67139000000000e-08,9.61481000000000e-08,2.60670000000000e-08,1.55002000000000e-07,8.23878000000000e-10,9.60602000000000e-08,5.86729000000000e-08,7.90744000000000e-08,2.28907000000000e-07,1.34009000000000e-07,1.42335000000000e-07,2.15318000000000e-07,2.28217000000000e-07,2.54539000000000e-07,4.08951000000000e-07,4.56468000000000e-07,7.10063000000000e-07,9.48876000000000e-07,1.14611000000000e-06,1.60426000000000e-06,2.22512000000000e-06,2.99576000000000e-06,4.15568000000000e-06,5.71424000000000e-06,8.00649000000000e-06,1.12000000000000e-05,1.55000000000000e-05,2.12000000000000e-05,2.91000000000000e-05,4.03000000000000e-05,5.59000000000000e-05,7.80000000000000e-05,0.000110500000000000,0.000158700000000000,0.000230200000000000,0.000341800000000000,0.000524300000000000,0.000835600000000000,0.00137400000000000,0.00236900000000000,0.00432350000000000,0.00836860000000000,0.0176434000000000,0.0400335000000000,0.0936216000000000,0.199991500000000,0.343882800000000,0.461721900000000,0.520060300000000,0.545697900000000,0.566132900000000,0.582429200000000,0.587477600000000,0.574678300000000,0.525402900000000,0.416985100000000,0.270482700000000,0.139567800000000,0.0662912000000000,0.0305382000000000,0.0149230000000000,0.00790830000000000,0.00442270000000000,0.00263620000000000,0.00165020000000000,0.00107810000000000,0.000729200000000000,0.000504700000000000,0.000357900000000000,0.000259300000000000,0.000192200000000000,0.000145300000000000,0.000111900000000000,8.70000000000000e-05,6.92000000000000e-05,5.55000000000000e-05,4.51000000000000e-05,3.72000000000000e-05,3.10000000000000e-05,2.60000000000000e-05,2.18000000000000e-05,1.86000000000000e-05,1.60000000000000e-05,1.38000000000000e-05,1.19000000000000e-05,1.05000000000000e-05,9.43210000000000e-06,8.34203000000000e-06,7.26519000000000e-06,6.56724000000000e-06,5.90878000000000e-06,5.37461000000000e-06,4.78343000000000e-06,4.31541000000000e-06,4.08582000000000e-06,3.63699000000000e-06,3.39491000000000e-06,3.18914000000000e-06,2.99680000000000e-06,2.75121000000000e-06,2.46158000000000e-06,2.29808000000000e-06,2.21647000000000e-06,1.90718000000000e-06,1.92036000000000e-06,1.74835000000000e-06,1.58198000000000e-06,1.56113000000000e-06,1.47214000000000e-06,1.34834000000000e-06,1.20977000000000e-06,1.17367000000000e-06,9.70003000000000e-07,9.97696000000000e-07,9.07885000000000e-07,9.20512000000000e-07,7.87469000000000e-07,7.11023000000000e-07,6.95809000000000e-07,5.53683000000000e-07,5.44335000000000e-07,5.05724000000000e-07,4.66090000000000e-07,4.75304000000000e-07,3.68967000000000e-07,4.89344000000000e-07,2.98463000000000e-07,3.41653000000000e-07,3.15294000000000e-07,2.73014000000000e-07,2.28440000000000e-07,2.44676000000000e-07,1.89754000000000e-07,2.17484000000000e-07,1.99742000000000e-07,1.53119000000000e-07,1.93895000000000e-07,1.55539000000000e-07,2.52935000000000e-07,1.57331000000000e-07,1.08131000000000e-07,1.62185000000000e-07,2.26637000000000e-07,1.42815000000000e-07,1.63835000000000e-07,1.12674000000000e-07,3.25114000000000e-07,1.19616000000000e-07,2.09501000000000e-07,1.84168000000000e-07,2.67369000000000e-07,1.86267000000000e-07,1.21533000000000e-07,2.98437000000000e-07,2.29882000000000e-07,1.72101000000000e-07,3.16782000000000e-07,2.23901000000000e-07,2.57427000000000e-07,4.27823000000000e-07,2.74351000000000e-07,2.85470000000000e-07,4.38473000000000e-07,5.31911000000000e-07,5.07178000000000e-07,4.11426000000000e-07,7.05582000000000e-07,7.40529000000000e-07,8.62314000000000e-07,1.27495000000000e-06,1.42757000000000e-06,1.70310000000000e-06;8.43110000000000e-09,4.67722000000000e-08,6.84230000000000e-08,2.61865000000000e-08,4.42569000000000e-08,2.54873000000000e-08,2.93571000000000e-08,3.03741000000000e-08,4.98204000000000e-08,3.19525000000000e-08,2.19027000000000e-08,9.85296000000000e-08,6.78285000000000e-08,7.10162000000000e-08,7.81312000000000e-08,1.41937000000000e-07,6.18076000000000e-08,1.21017000000000e-08,8.88913000000000e-08,3.92840000000000e-08,5.96903000000000e-08,5.34592000000000e-08,1.16939000000000e-07,2.56502000000000e-08,5.79673000000000e-08,7.39275000000000e-08,1.14880000000000e-08,2.22491000000000e-08,8.05106000000000e-09,1.12760000000000e-07,8.93272000000000e-08,2.62668000000000e-08,3.12964000000000e-08,9.41967000000000e-08,1.77694000000000e-09,4.97746000000000e-08,1.74396000000000e-08,3.77341000000000e-08,9.96065000000000e-08,2.69687000000000e-08,5.63137000000000e-08,2.47935000000000e-08,8.34473000000000e-09,5.67702000000000e-08,1.31242000000000e-07,4.89852000000000e-08,2.09153000000000e-08,1.13702000000000e-07,3.50827000000000e-08,4.79396000000000e-08,7.78049000000000e-08,2.50927000000000e-08,4.40313000000000e-08,2.44039000000000e-08,1.15046000000000e-07,3.50845000000000e-08,2.09759000000000e-08,1.12563000000000e-08,3.63701000000000e-08,1.28050000000000e-07,1.66727000000000e-08,1.08021000000000e-09,7.50083000000000e-08,1.82691000000000e-08,7.43380000000000e-08,5.95292000000000e-09,1.35362000000000e-08,4.16818000000000e-08,4.28611000000000e-08,2.37261000000000e-08,4.89093000000000e-08,1.65019000000000e-08,1.75686000000000e-08,3.41971000000000e-09,5.42858000000000e-08,1.30751000000000e-07,1.26905000000000e-08,4.60641000000000e-08,6.30126000000000e-08,2.38214000000000e-08,4.02519000000000e-08,2.81496000000000e-08,2.66102000000000e-08,6.13690000000000e-08,1.87949000000000e-09,6.52409000000000e-08,1.96902000000000e-08,5.51851000000000e-09,3.51425000000000e-08,1.22297000000000e-08,1.85185000000000e-08,5.19318000000000e-08,1.92431000000000e-09,4.89710000000000e-08,4.75137000000000e-08,7.51202000000000e-08,5.02372000000000e-08,2.23882000000000e-09,5.62608000000000e-08,1.03739000000000e-07,1.83789000000000e-08,1.23351000000000e-08,3.49136000000000e-08,2.38105000000000e-08,2.58647000000000e-08,3.26889000000000e-08,1.05203000000000e-07,1.10929000000000e-08,6.15723000000000e-09,2.89057000000000e-08,2.26151000000000e-08,5.74459000000000e-08,1.48800000000000e-08,3.28845000000000e-08,4.24309000000000e-08,1.88398000000000e-08,2.42936000000000e-08,7.84567000000000e-08,8.68114000000000e-09,5.40724000000000e-08,5.69663000000000e-09,6.76733000000000e-08,4.19357000000000e-08,1.71887000000000e-09,1.25082000000000e-07,7.36096000000000e-09,5.47037000000000e-08,5.74032000000000e-08,1.00495000000000e-07,2.53138000000000e-08,7.32120000000000e-08,2.81173000000000e-08,2.33947000000000e-08,6.76852000000000e-08,4.50815000000000e-09,1.30693000000000e-07,3.84348000000000e-08,2.17673000000000e-08,1.25573000000000e-08,2.16383000000000e-08,6.16838000000000e-08,4.70570000000000e-08,3.00691000000000e-08,8.87312000000000e-08,4.36696000000000e-09,1.52548000000000e-07,1.12286000000000e-08,8.62033000000000e-08,5.42476000000000e-08,3.02327000000000e-08,1.19726000000000e-07,1.00804000000000e-07,3.82707000000000e-08,1.23985000000000e-07,1.06129000000000e-07,7.23300000000000e-08,1.73688000000000e-07,1.22991000000000e-07,2.48846000000000e-07,1.65884000000000e-07,2.63766000000000e-07,2.23683000000000e-07,3.01427000000000e-07,2.96163000000000e-07,3.33611000000000e-07,3.88106000000000e-07,5.58888000000000e-07,4.32108000000000e-07,6.31834000000000e-07,5.66822000000000e-07,7.67632000000000e-07,9.08622000000000e-07,9.15802000000000e-07,1.03292000000000e-06,1.35054000000000e-06,1.34611000000000e-06,1.48869000000000e-06,1.79701000000000e-06,2.14505000000000e-06,2.27847000000000e-06,2.62166000000000e-06,2.79698000000000e-06,3.45419000000000e-06,3.74800000000000e-06,4.37322000000000e-06,4.79560000000000e-06,5.77969000000000e-06,6.57822000000000e-06,7.68842000000000e-06,8.99776000000000e-06,1.08000000000000e-05,1.27000000000000e-05,1.53000000000000e-05,1.83000000000000e-05,2.23000000000000e-05,2.78000000000000e-05,3.47000000000000e-05,4.41000000000000e-05,5.65000000000000e-05,7.34000000000000e-05,9.71000000000000e-05,0.000130200000000000,0.000177200000000000,0.000245300000000000,0.000349500000000000,0.000508000000000000,0.000758000000000000,0.00116670000000000,0.00187440000000000,0.00316860000000000,0.00567710000000000,0.0109402000000000,0.0225544000000000,0.0500902000000000,0.114063700000000,0.234557000000000,0.382301300000000,0.497943400000000,0.545451600000000,0.551811400000000,0.544192500000000,0.529845400000000,0.513413600000000,0.500199500000000,0.470442000000000,0.386288300000000,0.252140000000000,0.119176100000000,0.0561785000000000,0.0248051000000000,0.0116417000000000,0.00595570000000000,0.00326640000000000,0.00189340000000000,0.00115890000000000,0.000732600000000000,0.000481500000000000,0.000324600000000000,0.000224600000000000,0.000158700000000000,0.000112900000000000,8.16000000000000e-05,6.00000000000000e-05,4.44000000000000e-05,3.36000000000000e-05,2.54000000000000e-05,1.92000000000000e-05,1.49000000000000e-05,1.17000000000000e-05,9.02781000000000e-06,7.14605000000000e-06,5.60704000000000e-06,4.50274000000000e-06,3.55883000000000e-06,2.86774000000000e-06,2.23599000000000e-06,1.82185000000000e-06,1.51243000000000e-06,1.30442000000000e-06,9.99929000000000e-07,8.02879000000000e-07,6.75683000000000e-07,6.02494000000000e-07,4.59423000000000e-07,3.82546000000000e-07,4.05968000000000e-07,2.85131000000000e-07,3.69780000000000e-07,1.65283000000000e-07,1.87411000000000e-07,1.44094000000000e-07,2.69771000000000e-07,1.20985000000000e-07,8.63500000000000e-08,8.17203000000000e-08,1.63913000000000e-07,8.82316000000000e-08,5.04810000000000e-08,6.81551000000000e-08,1.70585000000000e-07,6.12022000000000e-08,3.19954000000000e-08,1.37844000000000e-07,2.21065000000000e-08,2.22466000000000e-09,1.51001000000000e-07,1.15706000000000e-08,5.28436000000000e-08,1.13248000000000e-07,5.88687000000000e-08,2.07533000000000e-08,2.84072000000000e-08,1.60437000000000e-07,1.30140000000000e-07,4.91392000000000e-08,6.58659000000000e-08,7.80016000000000e-08,3.72685000000000e-08,1.06315000000000e-07,3.15052000000000e-08,5.89717000000000e-08;7.58767000000000e-08,1.03266000000000e-07,4.43913000000000e-08,7.03195000000000e-08,8.60849000000000e-08,1.82248000000000e-08,7.10021000000000e-08,4.60095000000000e-08,4.37355000000000e-08,1.51792000000000e-07,5.90629000000000e-09,3.85287000000000e-10,6.31287000000000e-08,5.90067000000000e-08,4.73286000000000e-08,9.71778000000000e-08,8.39550000000000e-08,8.05243000000000e-08,9.97183000000000e-08,9.12333000000000e-08,7.72285000000000e-09,8.69646000000000e-09,4.75649000000000e-08,8.65936000000000e-09,2.29922000000000e-08,5.87535000000000e-08,1.83923000000000e-08,2.63557000000000e-08,5.81901000000000e-08,4.59076000000000e-08,4.81082000000000e-08,2.43935000000000e-08,5.14593000000000e-09,6.45555000000000e-08,4.54200000000000e-08,1.51584000000000e-07,1.02282000000000e-07,1.92589000000000e-08,7.66705000000000e-08,3.44115000000000e-09,1.77039000000000e-08,1.70815000000000e-08,5.60753000000000e-08,2.67243000000000e-08,1.74157000000000e-07,1.40951000000000e-08,3.14127000000000e-08,6.79768000000000e-09,4.04916000000000e-08,1.84522000000000e-09,2.47392000000000e-08,5.73460000000000e-08,4.14622000000000e-09,3.60051000000000e-08,8.11795000000000e-08,3.33823000000000e-08,5.97095000000000e-08,2.41677000000000e-08,3.99943000000000e-08,4.91277000000000e-08,6.99776000000000e-09,3.44684000000000e-08,4.65443000000000e-09,3.87898000000000e-08,1.76795000000000e-08,9.21052000000000e-09,4.01368000000000e-08,5.64139000000000e-08,5.24867000000000e-08,1.18336000000000e-08,4.67230000000000e-08,9.51853000000000e-09,2.83293000000000e-08,3.15380000000000e-08,2.53605000000000e-08,7.33159000000000e-08,1.07967000000000e-08,5.80345000000000e-09,3.61965000000000e-08,1.90666000000000e-08,5.52238000000000e-08,5.66950000000000e-08,7.67269000000000e-08,8.33328000000000e-08,1.82566000000000e-08,1.06889000000000e-07,5.68305000000000e-08,3.99499000000000e-08,4.37930000000000e-08,7.41770000000000e-08,4.45964000000000e-08,5.21264000000000e-08,2.16231000000000e-08,4.61832000000000e-08,6.55048000000000e-08,6.69455000000000e-08,2.87928000000000e-08,4.59589000000000e-08,1.08518000000000e-07,9.46160000000000e-08,1.46169000000000e-08,5.53431000000000e-08,7.75313000000000e-08,2.87238000000000e-09,3.48676000000000e-08,1.66265000000000e-08,5.80674000000000e-08,1.99941000000000e-08,1.80397000000000e-08,5.18452000000000e-08,2.68773000000000e-08,6.29434000000000e-08,5.48231000000000e-08,7.54721000000000e-09,6.53712000000000e-08,6.57700000000000e-08,1.96530000000000e-08,1.62893000000000e-07,3.94059000000000e-08,2.12147000000000e-08,3.77112000000000e-08,1.48524000000000e-08,6.12322000000000e-08,6.43520000000000e-09,1.59632000000000e-08,2.83673000000000e-09,1.09489000000000e-08,7.73805000000000e-08,2.11822000000000e-08,1.79817000000000e-08,8.08445000000000e-08,3.11710000000000e-08,4.23516000000000e-08,1.84480000000000e-08,5.75871000000000e-08,1.37538000000000e-07,5.37464000000000e-08,5.72727000000000e-08,4.74928000000000e-08,2.83703000000000e-08,3.47000000000000e-08,4.13299000000000e-08,9.93172000000000e-09,4.22345000000000e-08,3.12063000000000e-08,8.17297000000000e-08,2.41198000000000e-08,2.46478000000000e-08,6.23017000000000e-08,9.38535000000000e-08,6.16858000000000e-08,4.22007000000000e-08,2.17814000000000e-08,1.94677000000000e-08,2.08902000000000e-08,6.19784000000000e-08,1.16725000000000e-07,1.44330000000000e-08,1.03429000000000e-07,9.29733000000000e-09,6.08912000000000e-08,5.58146000000000e-08,4.87273000000000e-09,1.04620000000000e-07,2.29993000000000e-08,5.17495000000000e-08,8.74838000000000e-08,4.47215000000000e-08,1.29041000000000e-08,7.19977000000000e-08,2.69392000000000e-08,1.04704000000000e-07,7.04223000000000e-08,2.22238000000000e-09,1.78619000000000e-09,1.20070000000000e-08,1.84211000000000e-08,5.96587000000000e-08,2.15163000000000e-08,3.92548000000000e-08,3.10323000000000e-08,3.77868000000000e-08,1.42975000000000e-07,5.48379000000000e-09,1.06339000000000e-07,2.88572000000000e-08,1.39876000000000e-07,4.10469000000000e-08,4.54070000000000e-08,1.00902000000000e-07,5.09183000000000e-09,8.99079000000000e-08,3.24469000000000e-08,8.98390000000000e-09,1.43793000000000e-07,3.93131000000000e-08,2.52532000000000e-09,1.14893000000000e-07,6.19119000000000e-08,1.17994000000000e-07,1.68663000000000e-09,3.12291000000000e-08,6.92089000000000e-08,2.62571000000000e-08,4.22918000000000e-08,1.36553000000000e-07,2.36919000000000e-09,4.76382000000000e-08,1.47049000000000e-07,1.27253000000000e-07,2.08074000000000e-07,1.53410000000000e-07,2.30674000000000e-07,2.90773000000000e-07,3.31076000000000e-07,4.48402000000000e-07,6.36410000000000e-07,5.61694000000000e-07,8.05164000000000e-07,9.72078000000000e-07,1.32283000000000e-06,1.62285000000000e-06,1.99874000000000e-06,2.68839000000000e-06,3.40240000000000e-06,4.24880000000000e-06,5.45737000000000e-06,7.01303000000000e-06,9.07609000000000e-06,1.14000000000000e-05,1.46000000000000e-05,1.89000000000000e-05,2.42000000000000e-05,3.14000000000000e-05,4.02000000000000e-05,5.24000000000000e-05,6.87000000000000e-05,9.03000000000000e-05,0.000119800000000000,0.000160900000000000,0.000220500000000000,0.000308100000000000,0.000436600000000000,0.000632400000000000,0.000939700000000000,0.00143870000000000,0.00228530000000000,0.00375690000000000,0.00653030000000000,0.0119758000000000,0.0233640000000000,0.0480601000000000,0.101863700000000,0.204375200000000,0.348854900000000,0.477507500000000,0.551232000000000,0.577157400000000,0.583270700000000,0.580360900000000,0.571665300000000,0.560552000000000,0.541246200000000,0.486288300000000,0.373324800000000,0.232762000000000,0.118707200000000,0.0559726000000000,0.0267588000000000,0.0135520000000000,0.00735070000000000,0.00421740000000000,0.00253470000000000,0.00159910000000000,0.00104090000000000,0.000699800000000000,0.000482600000000000,0.000340400000000000,0.000246500000000000,0.000181200000000000,0.000135800000000000,0.000103400000000000,7.97000000000000e-05,6.23000000000000e-05,4.89000000000000e-05,3.89000000000000e-05,3.12000000000000e-05,2.54000000000000e-05,2.10000000000000e-05,1.73000000000000e-05,1.41000000000000e-05,1.21000000000000e-05,1.01000000000000e-05,8.58105000000000e-06,7.27520000000000e-06,6.37344000000000e-06,5.29397000000000e-06,4.53176000000000e-06,4.07826000000000e-06,3.38781000000000e-06,2.88571000000000e-06]';
                
            otherwise
                error('Unrecognized filter selection')
                
        end
        
        Filter.qty = size(trans,2);
        
        % Save raw input data
        Filter.T_orig   = trans;
        Filter.lam_orig = Filter.lambda;
        
        % Calculate CWL of each filter
        Filter.CWL = zeros(Filter.qty,1);
        CWL_res = get(CWL_Res.handle, 'string');
        CWL_res = str2double(CWL_res);
        for f = 1 : Filter.qty
            [~, ind] = max(trans(:,f));
            CWL = Filter.lambda(ind);
            CWL = round(CWL / CWL_res) * CWL_res;
            Filter.CWL(f) = CWL;
        end
        [~, Filter.ind_CWL] = intersect(Wavelength, Filter.CWL);
        if length(Filter.ind_CWL) ~= Filter.qty
            error('Filter CWL(s) not contained within wavelength domain')
        end
        
        figure(4)
            set(gcf,'Name','Filter Transmission Spectra','NumberTitle','off')
            clf
            hold on
            set(gcf,'color','white')
            x = Filter.lam_orig;
            for f = 1 : Filter.qty
                y = Filter.T_orig(:,f);
                plot(x, y, 'k')
                text(Filter.CWL(f), max(Filter.T_orig(:))+0.01, [num2str(f)], 'HorizontalAlignment','center', 'VerticalAlignment','bottom')
            end
            set(gca,'xtick', Filter.CWL)
            ylim([0 1])
            grid on
            grid minor
            xlabel('Wavelength, nm')
            ylabel('Transmission, 0-1, ~')
            title(['Filter: ' Filter.description])
        
    end

    %%
    
    function update_observer
        
        % Data source: http://cvrl.ioo.ucl.ac.uk/index.htm
        
        Observer.lambda = 360 : 5 : 830; % nm
        i_ob = get(Select_Observer.handle, 'value');
        Observer.description = Select_Observer.vals{i_ob};
        
        switch i_ob
            
            case 1 % CIE 1931 2� XYZ
                ob_sen = [
                            0.0001299 0.0002321 0.0004149 0.0007416 0.001368 0.002236 0.004243 0.00765 0.01431 0.02319 0.04351 0.07763 0.13438 0.21477 0.2839 0.3285 0.34828 0.34806 0.3362 0.3187 0.2908 0.2511 0.19536 0.1421 0.09564 0.05795001 0.03201 0.0147 0.0049 0.0024 0.0093 0.0291 0.06327 0.1096 0.1655 0.2257499 0.2904 0.3597 0.4334499 0.5120501 0.5945 0.6784 0.7621 0.8425 0.9163 0.9786 1.0263 1.0567 1.0622 1.0456 1.0026 0.9384 0.8544499 0.7514 0.6424 0.5419 0.4479 0.3608 0.2835 0.2187 0.1649 0.1212 0.0874 0.0636 0.04677 0.0329 0.0227 0.01584 0.01135916 0.008110916 0.005790346 0.004109457 0.002899327 0.00204919 0.001439971 0.0009999493 0.0006900786 0.0004760213 0.0003323011 0.0002348261 0.0001661505 0.000117413 8.307527E-05 5.870652E-05 4.150994E-05 2.935326E-05 2.067383E-05 1.455977E-05 1.025398E-05 7.221456E-06 5.085868E-06 3.581652E-06 2.522525E-06 1.776509E-06 1.251141E-06
                            3.917E-06 6.965E-06 1.239E-05 2.202E-05 3.9E-05 6.4E-05 0.00012 0.000217 0.000396 0.00064 0.00121 0.00218 0.004 0.0073 0.0116 0.01684 0.023 0.0298 0.038 0.048 0.06 0.0739 0.09098 0.1126 0.13902 0.1693 0.20802 0.2586 0.323 0.4073 0.503 0.6082 0.71 0.7932 0.862 0.9148501 0.954 0.9803 0.9949501 1 0.995 0.9786 0.952 0.9154 0.87 0.8163 0.757 0.6949 0.631 0.5668 0.503 0.4412 0.381 0.321 0.265 0.217 0.175 0.1382 0.107 0.0816 0.061 0.04458 0.032 0.0232 0.017 0.01192 0.00821 0.005723 0.004102 0.002929 0.002091 0.001484 0.001047 0.00074 0.00052 0.0003611 0.0002492 0.0001719 0.00012 8.48E-05 6E-05 4.24E-05 3E-05 2.12E-05 1.499E-05 1.06E-05 7.4657E-06 5.2578E-06 3.7029E-06 2.6078E-06 1.8366E-06 1.2934E-06 9.1093E-07 6.4153E-07 4.5181E-07
                            0.0006061 0.001086 0.001946 0.003486 0.006450001 0.01054999 0.02005001 0.03621 0.06785001 0.1102 0.2074 0.3713 0.6456 1.0390501 1.3856 1.62296 1.74706 1.7826 1.77211 1.7441 1.6692 1.5281 1.28764 1.0419 0.8129501 0.6162 0.46518 0.3533 0.272 0.2123 0.1582 0.1117 0.07824999 0.05725001 0.04216 0.02984 0.0203 0.0134 0.008749999 0.005749999 0.0039 0.002749999 0.0021 0.0018 0.001650001 0.0014 0.0011 0.001 0.0008 0.0006 0.00034 0.00024 0.00019 1E-04 4.999999E-05 3E-05 2E-05 1E-05 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
                         ];
                
            case 2 % CIE 1964 10� XYZ
                ob_sen = [
                            1.222E-07 9.1927E-07 5.9586E-06 3.3266E-05 0.000159952 0.00066244 0.0023616 0.0072423 0.0191097 0.0434 0.084736 0.140638 0.204492 0.264737 0.314679 0.357719 0.383734 0.386726 0.370702 0.342957 0.302273 0.254085 0.195618 0.132349 0.080507 0.041072 0.016172 0.005132 0.003816 0.015444 0.037465 0.071358 0.117749 0.172953 0.236491 0.304213 0.376772 0.451584 0.529826 0.616053 0.705224 0.793832 0.878655 0.951162 1.01416 1.0743 1.11852 1.1343 1.12399 1.0891 1.03048 0.95074 0.856297 0.75493 0.647467 0.53511 0.431567 0.34369 0.268329 0.2043 0.152568 0.11221 0.0812606 0.05793 0.0408508 0.028623 0.0199413 0.013842 0.00957688 0.0066052 0.00455263 0.0031447 0.00217496 0.0015057 0.00104476 0.00072745 0.000508258 0.00035638 0.000250969 0.00017773 0.00012639 9.0151E-05 6.45258E-05 4.6339E-05 3.34117E-05 2.4209E-05 1.76115E-05 1.2855E-05 9.41363E-06 6.913E-06 5.09347E-06 3.7671E-06 2.79531E-06 2.082E-06 1.55314E-06
                            1.3398E-08 1.0065E-07 6.511E-07 3.625E-06 1.7364E-05 7.156E-05 0.0002534 0.0007685 0.0020044 0.004509 0.008756 0.014456 0.021391 0.029497 0.038676 0.049602 0.062077 0.074704 0.089456 0.106256 0.128201 0.152761 0.18519 0.21994 0.253589 0.297665 0.339133 0.395379 0.460777 0.53136 0.606741 0.68566 0.761757 0.82333 0.875211 0.92381 0.961988 0.9822 0.991761 0.99911 0.99734 0.98238 0.955552 0.915175 0.868934 0.825623 0.777405 0.720353 0.658341 0.593878 0.527963 0.461834 0.398057 0.339554 0.283493 0.228254 0.179828 0.140211 0.107633 0.081187 0.060281 0.044096 0.0318004 0.0226017 0.0159051 0.0111303 0.0077488 0.0053751 0.00371774 0.00256456 0.00176847 0.00122239 0.00084619 0.00058644 0.00040741 0.000284041 0.00019873 0.00013955 9.8428E-05 6.9819E-05 4.9737E-05 3.55405E-05 2.5486E-05 1.83384E-05 1.3249E-05 9.6196E-06 7.0128E-06 5.1298E-06 3.76473E-06 2.77081E-06 2.04613E-06 1.51677E-06 1.12809E-06 8.4216E-07 6.297E-07
                            5.35027E-07 4.0283E-06 2.61437E-05 0.00014622 0.000704776 0.0029278 0.0104822 0.032344 0.0860109 0.19712 0.389366 0.65676 0.972542 1.2825 1.55348 1.7985 1.96728 2.0273 1.9948 1.9007 1.74537 1.5549 1.31756 1.0302 0.772125 0.57006 0.415254 0.302356 0.218502 0.159249 0.112044 0.082248 0.060709 0.04305 0.030451 0.020584 0.013676 0.007918 0.003988 0.001091 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
                         ];

        end
        
        ob_sen = ob_sen';
        Observer.sensitivity = zeros(length(Wavelength), 3);
        for cc = 1 : 3
            Observer.sensitivity(:,cc) = interp1(Observer.lambda, ob_sen(:,cc), Wavelength);
        end
        Observer.lambda = Wavelength;
        
        figure(2)
            set(gcf,'Name','Observer','NumberTitle','off')
            clf
            hold on
            set(gcf,'color','white')
            for cc = 1 : 3
                col = [0 0 0];
                col(cc) = 1;
                plot(Observer.lambda, Observer.sensitivity(:,cc), 'Color', col,'LineWidth',2)
            end
            grid on
            grid minor
            xlabel('Wavelength, nm')
            ylabel('Sensitivity, ~')
            title(['Observer: ' Observer.description])
            xlim(lambda_lims)
            ylim([0 max(ylim)])
            legend({'$\bar{x}$','$\bar{y}$','$\bar{z}$'},'location','northeast','Interpreter','Latex','FontSize',12)
            
        update_filters
        
    end

    %%
    
    function update_camera
        
        % Data source: http://www.gujinwei.org/research/camspec/db.html
        
        Camera.lambda = 400 : 10 : 720; % nm, default
        i_cam = get(Select_Camera.handle, 'value');
        Camera.description = Select_Camera.vals{i_cam};
        
        switch i_cam
        
            case 1
                    cam_sen = [
                    0.0005826 0.0015345 0.0032648 0.0017968 0.0011327 0.0010138 0.0012358 0.0015814 0.0023156 0.0033231 0.0099827 0.019719 0.052282 0.11518 0.12991 0.10525 0.14334 0.28241 0.31153 0.55747 0.5377 0.49413 0.42527 0.36399 0.27563 0.21406 0.14996 0.068701 0.012535 0.0023522 0.00050291 0.00013838 4.4186e-05
                    0.0022632 0.0090549 0.040708 0.047983 0.069255 0.098384 0.11977 0.16981 0.31083 0.46114 0.94734 0.83935 0.89683 1 0.92794 0.87725 0.74845 0.63893 0.33715 0.32125 0.1676 0.082557 0.043512 0.029175 0.019359 0.013462 0.010043 0.0062015 0.0016749 0.00044468 0.00013311 3.9683e-05 1.7053e-05
                    0.010972 0.08325 0.41186 0.57035 0.71985 0.76168 0.8411 0.82581 0.78355 0.62952 0.68337 0.30674 0.14434 0.072663 0.041467 0.022853 0.010411 0.0064022 0.0032002 0.0032854 0.0022498 0.0014714 0.0012154 0.0011413 0.0013655 0.0017246 0.0019172 0.0011647 0.00023847 5.004e-05 1.6586e-05 9.5302e-06 8.494e-06
                    ];
            case 2
                    cam_sen = [
                    0.0012373 0.0030106 0.011758 0.025271 0.010475 0.0049324 0.0037963 0.0036845 0.005474 0.0078774 0.01422 0.033682 0.066095 0.12261 0.13197 0.10957 0.135 0.27359 0.43435 0.57273 0.58401 0.55905 0.4565 0.41415 0.31124 0.27841 0.19971 0.11555 0.020638 0.0060597 0.0017974 0.00047773 0.000199
                    0.001769 0.002598 0.012201 0.048114 0.06259 0.10033 0.1265 0.17166 0.31169 0.45374 0.624 0.83267 0.87769 1 0.89233 0.91122 0.74353 0.67042 0.5035 0.36099 0.20583 0.1099 0.054814 0.038684 0.025423 0.020145 0.015219 0.011671 0.0030243 0.0012578 0.00047442 0.00015524 8.7066e-05
                    0.0042219 0.014449 0.10198 0.4902 0.56697 0.68024 0.76452 0.77047 0.76653 0.63452 0.48636 0.35011 0.17535 0.092933 0.051083 0.031774 0.014149 0.0096536 0.0069416 0.0052074 0.0031756 0.0025481 0.0022039 0.0024109 0.0019002 0.0025228 0.0028168 0.0020036 0.00045075 0.00018058 0.00010512 8.9203e-05 8.1775e-05
                    ];
            case 3
                    cam_sen = [
                    0.0074301 0.0075795 0.0083043 0.0098831 0.010432 0.011028 0.01193 0.013319 0.01075 0.0071592 0.007603 0.0095502 0.013374 0.011634 0.010348 0.016463 0.1081 0.39461 0.5796 0.70646 0.65966 0.64128 0.48616 0.40497 0.32996 0.26965 0.19645 0.068429 0.015261 0.0062609 0.002577 0.00073993 0.00018341
                    0.041477 0.058 0.072545 0.10017 0.1198 0.16235 0.23092 0.36946 0.45982 0.50908 0.69947 0.84752 0.99131 0.99574 0.93826 0.88043 0.67937 0.57855 0.4181 0.29859 0.15914 0.083305 0.039898 0.025915 0.018503 0.012969 0.010731 0.0048377 0.0016101 0.00095847 0.00056323 0.00019049 7.9922e-05
                    0.26332 0.42981 0.53966 0.69805 0.77811 0.95757 0.97645 1 0.94768 0.84684 0.7179 0.49589 0.31392 0.17227 0.09118 0.041019 0.014928 0.0090299 0.0055769 0.0046034 0.0024248 0.0020683 0.0016975 0.0013351 0.0017914 0.0012195 0.0018138 0.00064544 0.00019937 0.00010163 6.6623e-05 2.6923e-05 3.7135e-05
                    ];
            case 4
                    cam_sen = [
                    0.00061338 0.00054295 0.0017657 0.0025753 0.0019556 0.0020464 0.0025927 0.0046451 0.0096604 0.013702 0.02004 0.03468 0.058077 0.1147 0.12768 0.11141 0.1335 0.24922 0.37219 0.50684 0.51487 0.49491 0.39493 0.36069 0.28328 0.23648 0.17385 0.13989 0.093123 0.027774 0.0050271 0.0012686 0.0005405
                    0.0022326 0.0025282 0.015147 0.039169 0.05659 0.070041 0.086096 0.18752 0.44622 0.63039 0.76014 0.93533 0.91804 1 0.86269 0.86491 0.7561 0.67191 0.52369 0.4122 0.24592 0.12807 0.05879 0.037918 0.024125 0.016853 0.011789 0.012027 0.011431 0.0048331 0.00118 0.00036413 0.00015703
                    0.0095762 0.019397 0.20048 0.63618 0.74402 0.8273 0.89143 0.86181 0.84141 0.72815 0.55543 0.42602 0.23653 0.14648 0.089427 0.065516 0.040818 0.031477 0.025019 0.020957 0.01404 0.0093475 0.0060651 0.0057769 0.0054316 0.0060976 0.0059716 0.0060196 0.004393 0.0014347 0.00028048 8.9175e-05 5.2324e-05
                    ];
            case 5
                    cam_sen = [
                    0.0047882 0.006503 0.014181 0.0090063 0.0072716 0.008399 0.012928 0.023407 0.042132 0.06015 0.079772 0.11068 0.1296 0.1528 0.17491 0.23995 0.27103 0.35363 0.59207 0.56519 0.50552 0.48372 0.40474 0.35005 0.26818 0.22628 0.17275 0.13367 0.060161 0.012976 0.0026525 0.00064602 0.00064602
                    0.0063344 0.01322 0.056945 0.072339 0.10335 0.12163 0.16863 0.33452 0.58549 0.72721 0.82791 0.94525 0.93856 1 0.91351 0.90129 0.74393 0.68775 0.65043 0.45765 0.29386 0.17488 0.10517 0.076 0.053159 0.042043 0.032367 0.029075 0.016249 0.0045584 0.0010866 0.00030439 0.00030439
                    0.031083 0.094291 0.48083 0.67493 0.76173 0.82236 0.86969 0.84873 0.82207 0.7235 0.58539 0.46393 0.30706 0.23495 0.18321 0.1615 0.11978 0.10939 0.11367 0.087972 0.064425 0.047167 0.034519 0.02963 0.024397 0.023239 0.020503 0.018144 0.009073 0.0022567 0.00049182 0.00014889 0.00014889
                    ];
            case 6
                    cam_sen = [
                    0.0028702 0.0041069 0.011116 0.0073087 0.006094 0.0077521 0.011988 0.020974 0.040081 0.057985 0.078288 0.10762 0.12367 0.14337 0.16177 0.21597 0.24571 0.31892 0.47163 0.5751 0.52469 0.50401 0.41372 0.36871 0.27449 0.24825 0.18265 0.12534 0.038161 0.0071614 0.0015313 0.00041294 0.00013442
                    0.0038429 0.0084168 0.04719 0.059687 0.07931 0.101 0.14369 0.29073 0.55534 0.71604 0.83415 0.96078 0.95231 1 0.90476 0.91429 0.77717 0.69504 0.59941 0.48003 0.30101 0.18953 0.10826 0.079299 0.055709 0.046082 0.03412 0.026783 0.010069 0.0023621 0.00062366 0.0001877 7.6367e-05
                    0.019794 0.073244 0.50542 0.74601 0.76997 0.865 0.93131 0.86648 0.82817 0.72488 0.57322 0.44985 0.29398 0.22272 0.17535 0.15767 0.12188 0.11012 0.10481 0.094114 0.067215 0.050614 0.035484 0.030552 0.02425 0.023529 0.019692 0.015408 0.0053095 0.0011014 0.00028127 9.5952e-05 5.6264e-05
                    ];
            case 7
                    cam_sen = [
                    0.0019 0.0045 0.0103 0.0055 0.0034 0.0021 0.0023 0.0039 0.0073 0.0118 0.0179 0.0612 0.0874 0.1534 0.1686 0.1724 0.2003 0.3158 0.4514 0.5258 0.5989 0.4728 0.4084 0.3562 0.292 0.226 0.1704 0.1372 0.0428 0.0087 0.0017 0.0007 0.0005
                    0.0036 0.0123 0.0377 0.0422 0.0565 0.0704 0.097 0.209 0.43 0.6381 0.692 1 0.8735 0.9058 0.8326 0.8057 0.712 0.6467 0.5426 0.3935 0.2958 0.1287 0.06 0.0402 0.0276 0.0182 0.0138 0.0143 0.0061 0.0017 0.0008 0.0006 0.0005
                    0.0127 0.0971 0.3516 0.4765 0.56 0.6476 0.7745 0.6759 0.6858 0.5932 0.3971 0.3559 0.1617 0.0883 0.0551 0.0424 0.0269 0.0205 0.0159 0.0122 0.01 0.0054 0.0036 0.0032 0.0029 0.0032 0.0032 0.0034 0.0013 0.0005 0.0004 0.0004 0.0004
                    ];
            case 8
                    cam_sen = [
                    0.0018383 0.0034546 0.0065563 0.0064237 0.003663 0.0032176 0.0045901 0.0075219 0.015409 0.022585 0.033511 0.053847 0.066262 0.082616 0.10166 0.15313 0.2023 0.29541 0.4398 0.53074 0.51692 0.50521 0.38884 0.34276 0.26434 0.22089 0.1637 0.13044 0.072591 0.021389 0.003813 0.00089247 0.00023267
                    0.0027522 0.0063568 0.025923 0.055392 0.079072 0.098383 0.13411 0.28424 0.53216 0.67504 0.78346 0.91032 0.89359 1 0.88185 0.85526 0.76181 0.71016 0.56299 0.44008 0.27856 0.16213 0.078769 0.052859 0.035122 0.026057 0.018983 0.01922 0.014806 0.005949 0.0013347 0.00034954 0.00012156
                    0.010963 0.047664 0.25927 0.6278 0.69721 0.78211 0.8035 0.78122 0.75824 0.64609 0.513 0.38666 0.22351 0.15669 0.10477 0.078029 0.050767 0.040953 0.034064 0.027857 0.019411 0.013821 0.0088981 0.0081423 0.007593 0.0084223 0.008274 0.0083911 0.0053867 0.0018156 0.00036101 0.00011979 7.6506e-05
                    ];
            case 9
                    cam_sen = [
                    0.0036939 0.005789 0.011972 0.0060098 0.0035058 0.0030138 0.003971 0.0069487 0.016477 0.024973 0.033583 0.052786 0.063128 0.080597 0.099936 0.15863 0.19919 0.292 0.44402 0.5472 0.51815 0.51012 0.40294 0.35347 0.2762 0.23435 0.17264 0.13178 0.054995 0.0090115 0.0020717 0.00053755 0.00014563
                    0.0040156 0.010547 0.044575 0.050839 0.070745 0.091766 0.12786 0.27033 0.57034 0.62103 0.81123 0.93334 0.87925 1 0.90032 0.89821 0.75241 0.71861 0.56557 0.43987 0.27329 0.16099 0.077993 0.051902 0.034045 0.025987 0.018665 0.018169 0.010452 0.002445 0.00071102 0.00021753 8.286e-05
                    0.021702 0.097758 0.49898 0.65917 0.69625 0.80949 0.85447 0.7946 0.72031 0.621 0.52668 0.39733 0.21916 0.15569 0.10495 0.080773 0.050105 0.041103 0.033563 0.02794 0.019429 0.014083 0.0088883 0.0079959 0.0075041 0.008546 0.0082507 0.0081155 0.003858 0.00074718 0.00020182 7.4834e-05 5.0141e-05
                    ];
            case 10
                    cam_sen = [
                    0.011502 0.010943 0.0098142 0.0088809 0.0093476 0.010582 0.014842 0.023967 0.028472 0.029149 0.037155 0.044464 0.050044 0.058435 0.064967 0.069375 0.059423 0.063703 0.1075 0.3031 0.46938 0.51716 0.35002 0.32339 0.23393 0.16061 0.10761 0.076421 0.047979 0.026946 0.0179 0.011725 0.0071165
                    0.010796 0.014396 0.018709 0.025698 0.036083 0.054893 0.095247 0.18554 0.2677 0.326 0.4745 0.68586 0.86727 1 0.9579 0.93868 0.78328 0.67155 0.476 0.31097 0.13391 0.059444 0.022136 0.018125 0.012011 0.0085566 0.0065271 0.0060953 0.0052757 0.004191 0.0038902 0.0029877 0.0018729
                    0.2601 0.383 0.44232 0.52019 0.58406 0.71092 0.75957 0.82743 0.8576 0.80673 0.70256 0.56078 0.38489 0.25189 0.1491 0.090586 0.05356 0.0423 0.031948 0.026033 0.018909 0.015748 0.010347 0.010878 0.0088745 0.0073815 0.0058705 0.0049875 0.0036011 0.0023955 0.0019314 0.0013961 0.00089162
                    ];
            case 11
                    cam_sen = [
                    0.0024406 0.0074732 0.043482 0.041559 0.02767 0.024976 0.019662 0.025669 0.026141 0.024432 0.028678 0.032457 0.059491 0.070335 0.039702 0.018843 0.020206 0.07366 0.42166 0.65575 0.69133 0.54233 0.49941 0.36845 0.3249 0.24676 0.12792 0.019473 0.0039954 0.0012718 0.00041569 0.00023211 0.00020041
                    0.003237 0.0094721 0.070843 0.10274 0.11268 0.15445 0.19984 0.35789 0.40744 0.42311 0.63972 0.7795 0.97741 0.98932 1 0.95998 0.78072 0.66026 0.46838 0.29221 0.18126 0.084093 0.050509 0.030548 0.024419 0.017637 0.010018 0.0020529 0.00066224 0.00035024 0.00019089 0.00015702 0.00014449
                    0.011102 0.06039 0.50664 0.70704 0.70276 0.88834 0.85506 0.96314 0.79375 0.62957 0.52002 0.31329 0.19514 0.11409 0.077371 0.045768 0.020582 0.010729 0.0069893 0.0043945 0.0035622 0.0021654 0.0022762 0.0023488 0.00355 0.004849 0.0036772 0.00074569 0.00020708 0.0001167 8.3985e-05 8.1533e-05 7.6395e-05
                    ];
            case 12
                    cam_sen = [
                    0.0018193 0.0038708 0.026824 0.052216 0.03984 0.032337 0.027643 0.03134 0.03533 0.031916 0.033112 0.04109 0.068408 0.08229 0.036978 0.020338 0.022651 0.085913 0.45174 0.7935 0.69844 0.6309 0.50895 0.41911 0.32336 0.26999 0.17351 0.069569 0.014055 0.00244 0.0010628 0.00062523 0.00037755
                    0.0019233 0.0029811 0.022997 0.066951 0.082486 0.10762 0.15619 0.26645 0.34468 0.38234 0.54875 0.76082 0.90816 1 0.88019 0.92098 0.67471 0.56689 0.3965 0.27494 0.13136 0.06411 0.03338 0.021899 0.015473 0.012262 0.0090961 0.0052063 0.0016243 0.00045333 0.00028898 0.00020732 0.00014116
                    0.0057386 0.019403 0.22464 0.6404 0.71702 0.84433 0.83336 0.84318 0.76761 0.59667 0.40929 0.24069 0.10002 0.041642 0.018843 0.0090361 0.0024131 0.00141 0.00055508 0.00042896 0.00054569 0.00038823 0.00038026 0.00043686 0.0002603 0.0005734 0.0008241 0.00050455 0.00015639 6.7374e-05 5.7231e-05 4.5964e-05 3.8709e-05
                    ];
            case 13
                    cam_sen = [
                    0.0022762 0.0027981 0.033777 0.053485 0.040295 0.030923 0.026542 0.028605 0.033014 0.028928 0.031274 0.040259 0.061924 0.074348 0.038663 0.021882 0.025806 0.093019 0.4662 0.71759 0.67238 0.60074 0.48987 0.39157 0.30163 0.23531 0.15657 0.069783 0.014991 0.0031496 0.0010609 0.00047839 0.00025838
                    0.0016372 0.0017201 0.015367 0.038209 0.053617 0.072599 0.11985 0.22829 0.34829 0.38695 0.56813 0.79771 0.90616 1 0.92902 0.87187 0.73808 0.6016 0.41735 0.26827 0.12938 0.057778 0.027126 0.016111 0.01036 0.0069106 0.0050914 0.0033023 0.0011953 0.00037838 0.00020989 0.00012985 9.065e-05
                    0.007214 0.0137 0.27324 0.64383 0.75208 0.86078 0.89124 0.8552 0.81283 0.62369 0.4505 0.28966 0.13296 0.064311 0.031574 0.015213 0.0080397 0.0056782 0.0042467 0.0026458 0.0016533 0.0011252 0.00071852 0.00047297 0.00039955 0.00034232 0.000359 0.00023868 0.00013739 4.0654e-05 4.4266e-05 3.9222e-05 3.7601e-05
                    ];
            case 14
                    cam_sen = [
                    0.0034571 0.022312 0.053258 0.056944 0.048574 0.038908 0.037569 0.04308 0.0507 0.044813 0.049355 0.063254 0.10222 0.12954 0.069134 0.037013 0.043618 0.12534 0.54782 0.84149 0.78318 0.69242 0.55925 0.46851 0.36322 0.27167 0.17401 0.044063 0.0086769 0.010739 0.0042083 0.001273 0.00051675
                    0.0023428 0.012167 0.040045 0.064061 0.085339 0.10477 0.15962 0.26081 0.35429 0.36946 0.52444 0.75607 0.89915 1 0.90806 0.86275 0.73119 0.59194 0.42363 0.27365 0.14948 0.073612 0.038781 0.024961 0.018027 0.012848 0.0090382 0.0029268 0.00088953 0.0016742 0.0009277 0.00035903 0.00015305
                    0.010966 0.1081 0.37737 0.5801 0.70107 0.78943 0.87216 0.86767 0.84871 0.68103 0.53329 0.37727 0.22805 0.15406 0.09479 0.05434 0.025207 0.013388 0.0083187 0.0029447 0.0020306 0.0010572 0.00088583 0.0019322 0.003346 0.0049289 0.0047382 0.0014405 0.00035371 0.0005194 0.00025012 7.6169e-05 3.5843e-05
                    ];
            case 15
                    cam_sen = [
                    0.024961 0.021143 0.016001 0.013401 0.010463 0.0087063 0.0086141 0.013979 0.016986 0.015455 0.020048 0.036633 0.074621 0.096479 0.051559 0.031727 0.035235 0.11061 0.45053 0.67508 0.57488 0.50065 0.37559 0.30117 0.21377 0.1553 0.11482 0.078742 0.050859 0.035537 0.022129 0.015214 0.0098467
                    0.034887 0.04937 0.064249 0.086794 0.10102 0.13099 0.18292 0.2921 0.38557 0.42725 0.55215 0.78889 0.88258 1 0.9037 0.87539 0.69789 0.57496 0.38678 0.26582 0.11845 0.048996 0.019448 0.010674 0.0059683 0.0034973 0.0028521 0.0031359 0.0034555 0.0038866 0.0035504 0.0029044 0.0018316
                    0.24055 0.40544 0.52555 0.67595 0.71895 0.82801 0.82871 0.7974 0.717 0.55303 0.36349 0.21781 0.085666 0.035779 0.018275 0.01122 0.0059166 0.0037644 0.0033937 0.0029309 0.0017556 0.0010915 0.00074624 0.00056884 0.00072842 0.00059219 0.00052411 0.00054205 0.00045661 0.00034872 0.0002792 0.00022718 0.00017178
                    ];
            case 16
                    cam_sen = [
                    0.030947 0.020803 0.01532 0.012161 0.010524 0.0089518 0.0092151 0.012548 0.017491 0.01513 0.0187 0.031169 0.057046 0.091871 0.05508 0.030477 0.029048 0.078283 0.36176 0.62673 0.58272 0.50466 0.37192 0.32153 0.23219 0.18052 0.12025 0.089647 0.063347 0.044492 0.028755 0.020863 0.013428
                    0.037561 0.041006 0.05126 0.068434 0.090222 0.11407 0.16832 0.25556 0.38431 0.39832 0.51016 0.71938 0.82527 1 0.91595 0.8951 0.7358 0.62785 0.44029 0.29459 0.1412 0.054981 0.019834 0.011132 0.0063134 0.003865 0.0027007 0.0032505 0.0040784 0.0048058 0.004563 0.0040483 0.0025173
                    0.27139 0.35929 0.44843 0.57582 0.68263 0.77689 0.85043 0.79244 0.76617 0.57293 0.39291 0.24589 0.1015 0.045772 0.023081 0.012789 0.0062062 0.0040567 0.0030307 0.002014 0.0013412 0.00070417 0.00050604 0.00042877 0.00040568 0.00052631 0.00058264 0.00054454 0.00047424 0.00036424 0.00026866 0.0001929 9.5792e-05
                    ];
            case 17
                    cam_sen = [
                    0.00097089 0.00134 0.0048558 0.048817 0.044511 0.035356 0.030637 0.036642 0.041505 0.04001 0.043407 0.056477 0.08949 0.10403 0.055194 0.032069 0.035018 0.099778 0.47462 0.73781 0.68091 0.54974 0.45754 0.37341 0.28683 0.20456 0.14802 0.086178 0.028748 0.0062384 0.0016265 0.00057043 0.000239
                    0.0019946 0.0023647 0.0090914 0.11687 0.15689 0.18795 0.2367 0.35642 0.43339 0.49941 0.64847 0.83476 0.94407 1 0.89984 0.82235 0.66898 0.56147 0.43028 0.31399 0.18273 0.09276 0.055687 0.039461 0.028244 0.019985 0.016292 0.012224 0.0056229 0.001666 0.00055689 0.00023285 0.00011066
                    0.0039847 0.00756 0.047137 0.64213 0.80799 0.90724 0.87403 0.89336 0.81728 0.71421 0.52892 0.36156 0.21874 0.14699 0.09114 0.052706 0.025948 0.01619 0.011749 0.0083959 0.0051847 0.0032014 0.0027784 0.0031136 0.004006 0.0046745 0.004914 0.0035581 0.0013669 0.00036175 0.00012044 5.7607e-05 3.2738e-05
                    ];
            case 18
                    cam_sen = [
                    0.0017775 0.0027445 0.048766 0.05565 0.039817 0.031348 0.026632 0.02811 0.032437 0.029863 0.031673 0.038347 0.06215 0.075373 0.039432 0.021926 0.02526 0.095391 0.49461 0.74372 0.71172 0.61752 0.51236 0.41128 0.3198 0.24236 0.16547 0.082116 0.02628 0.0073938 0.0028568 0.0011169 0.00047128
                    0.0014335 0.001874 0.02308 0.043356 0.059914 0.082364 0.13356 0.24498 0.35961 0.40937 0.57699 0.76619 0.90061 1 0.95495 0.88728 0.74714 0.6249 0.45115 0.2869 0.14489 0.065037 0.031947 0.019449 0.012242 0.0081427 0.0059358 0.0042266 0.0020565 0.0008812 0.00048014 0.0002376 0.00011756
                    0.0059157 0.014395 0.37455 0.65271 0.75309 0.90218 0.91167 0.86787 0.81577 0.64403 0.46041 0.27786 0.13072 0.064085 0.031748 0.015075 0.0074314 0.0053662 0.0041164 0.0026565 0.001269 0.00075685 0.00050643 0.0003322 0.0003053 0.00039176 0.00023539 0.00018848 8.047e-05 4.5734e-05 3.4504e-05 2.7962e-05 2.4659e-05
                    ];
            case 19
                    cam_sen = [
                    0.00070595 0.00452 0.030965 0.029562 0.023743 0.020482 0.016799 0.019393 0.022142 0.020545 0.021532 0.029992 0.053211 0.064737 0.029201 0.016091 0.019404 0.077173 0.46519 0.76703 0.68649 0.38112 0.48641 0.40757 0.32172 0.24689 0.13374 0.054813 0.016354 0.003514 0.00084611 0.00030472 0.00013349
                    0.0013331 0.0038321 0.032529 0.052289 0.068017 0.094502 0.13575 0.22776 0.30571 0.34755 0.49428 0.71777 0.87004 1 0.88465 0.85631 0.683 0.55913 0.37691 0.24388 0.11296 0.032638 0.026543 0.018608 0.013406 0.0098167 0.0064142 0.0036479 0.0017932 0.00060155 0.00022436 0.00011333 6.7575e-05
                    0.0035557 0.034702 0.24276 0.48238 0.42343 0.60914 0.80501 0.81328 0.76022 0.58183 0.36484 0.20447 0.080773 0.033215 0.015199 0.0064075 0.0022125 0.0012051 0.0010351 0.00042372 0.00085722 0.00062479 0.00035162 0.00030179 0.00074076 0.00042896 0.00035947 0.00023146 0.00010888 4.8753e-05 2.9122e-05 1.3817e-05 1.5469e-05
                    ];
            case 20
                    cam_sen = [
                    0.0028468 0.010062 0.061123 0.064116 0.047407 0.038726 0.034205 0.036572 0.047892 0.042438 0.043595 0.052616 0.077728 0.10753 0.06105 0.032554 0.031711 0.082284 0.38034 0.69515 0.64866 0.58339 0.43881 0.38277 0.27678 0.2214 0.14436 0.065292 0.012061 0.0023253 0.0006623 0.00033038 0.00023816
                    0.0021672 0.0067144 0.05263 0.080844 0.095359 0.11855 0.17451 0.27748 0.3775 0.38856 0.53093 0.77103 0.87177 1 0.92027 0.862 0.69384 0.57252 0.38985 0.26256 0.1333 0.068442 0.032339 0.02286 0.014809 0.011587 0.0083058 0.0048175 0.0013214 0.00037885 0.00016044 9.3286e-05 6.5383e-05
                    0.0091573 0.051434 0.44646 0.66315 0.71144 0.82987 0.90129 0.87253 0.83253 0.67033 0.51074 0.37096 0.20735 0.13943 0.085438 0.050472 0.022981 0.012293 0.0076535 0.0049382 0.0027535 0.0020545 0.0016008 0.002078 0.0028889 0.0040484 0.0039968 0.0022416 0.00049355 0.00010513 3.3758e-05 1.3442e-05 7.4428e-06
                    ];
            case 21
                    cam_sen = [
                    0.0023404 0.001859 0.0021612 0.0018785 0.0020483 0.0020453 0.0030901 0.0079493 0.015542 0.024933 0.045539 0.074702 0.11864 0.16129 0.16291 0.16386 0.15411 0.14902 0.42572 0.95723 1 0.70057 0.90976 0.93954 0.77878 0.4029 0.12257 0.061958 0.023989 0.0099138 0.0076878 0.0040222 0.0012967
                    0.014258 0.01572 0.021887 0.023455 0.033772 0.041642 0.070455 0.16539 0.28849 0.36037 0.51551 0.6732 0.86191 0.92522 0.87936 0.85065 0.76661 0.67318 0.54526 0.44673 0.29153 0.30535 0.1601 0.13353 0.11201 0.059331 0.019223 0.010816 0.0053431 0.0028583 0.0026006 0.0014277 0.0005178
                    0.25552 0.31293 0.45069 0.49407 0.53804 0.56515 0.60609 0.58896 0.51464 0.45436 0.35509 0.26297 0.21911 0.21638 0.19842 0.17893 0.15676 0.14759 0.13721 0.13343 0.10382 0.097638 0.075487 0.077247 0.072765 0.042964 0.01443 0.0082901 0.0037298 0.0015722 0.0014485 0.00087214 0.0003729
                    ];
            case 22
                    cam_sen = [
                    0.00034592 0.010199 0.005184 0.0049607 0.0029724 0.0025227 0.0030831 0.0070559 0.0097957 0.010551 0.016989 0.030186 0.062365 0.069585 0.040168 0.030826 0.037897 0.13547 0.5673 0.92248 0.95313 1 0.95402 0.95351 0.87276 0.46524 0.10583 0.026156 0.0062958 0.0025279 0.001483 0.00065316 0.00027681
                    0.00038792 0.034473 0.034483 0.047572 0.056008 0.081198 0.13554 0.25174 0.3468 0.40955 0.54996 0.73427 0.93904 0.99445 0.90907 0.8822 0.74852 0.6765 0.50713 0.34455 0.19699 0.13279 0.13731 0.13574 0.086111 0.048309 0.013992 0.0048695 0.0015321 0.00080409 0.00058834 0.00030924 0.00019203
                    0.00066009 0.37447 0.43369 0.59431 0.59036 0.6711 0.71871 0.78297 0.72719 0.63405 0.50882 0.33797 0.21616 0.12859 0.088313 0.06365 0.037555 0.030433 0.025461 0.0211 0.014922 0.013021 0.050514 0.0574 0.024004 0.01847 0.0059679 0.0018727 0.00046966 0.00029377 0.00024342 0.00020289 0.00015693
                    ];
            case 23
                    cam_sen = [
                    0.0049808 0.01324 0.032474 0.04951 0.039221 0.031842 0.028723 0.034804 0.03862 0.036058 0.040284 0.051897 0.084514 0.090879 0.046949 0.027348 0.032222 0.10306 0.43865 0.65269 0.6183 0.53463 0.42722 0.39099 0.29366 0.23901 0.18002 0.13061 0.064519 0.016309 0.0040171 0.0017064 0.00072382
                    0.0055936 0.01756 0.060556 0.13842 0.16021 0.19298 0.25488 0.38523 0.46323 0.50812 0.67264 0.85272 0.97998 1 0.91263 0.8471 0.6982 0.61689 0.43735 0.32102 0.19114 0.10265 0.060331 0.047761 0.033676 0.026768 0.023402 0.022181 0.015051 0.0051166 0.0015966 0.00074431 0.00030714
                    0.019764 0.078823 0.28986 0.64432 0.69923 0.78494 0.77941 0.79439 0.72823 0.59789 0.44472 0.29717 0.18358 0.12037 0.075069 0.042591 0.020624 0.013878 0.0094057 0.006884 0.0044255 0.0030641 0.0027575 0.0034938 0.0043175 0.0055521 0.0061552 0.0054675 0.0030272 0.00089895 0.00024816 9.7628e-05 3.8239e-05
                    ];
            case 24
                    cam_sen = [
                    0.0024923 0.019414 0.040583 0.035356 0.02622 0.021607 0.021548 0.031331 0.049979 0.05987 0.074838 0.090588 0.1305 0.13824 0.10283 0.093277 0.097758 0.14306 0.55529 0.87208 0.90595 0.90701 0.78333 0.79802 0.7359 0.73356 0.35899 0.078863 0.016321 0.0033198 0.0020004 0.0025379 0.0016567
                    0.002931 0.016955 0.035993 0.034338 0.04332 0.043915 0.060121 0.21311 0.58884 0.80776 0.93188 0.93449 1 0.98631 0.90467 0.86827 0.78979 0.72873 0.61537 0.57656 0.43959 0.31821 0.21731 0.19666 0.16993 0.16209 0.081103 0.021748 0.0058041 0.0014868 0.0010705 0.0014108 0.00090384
                    0.013803 0.16995 0.53654 0.64831 0.63645 0.68501 0.6835 0.6909 0.65012 0.54691 0.44026 0.30707 0.23016 0.1785 0.1389 0.11161 0.091379 0.084556 0.080833 0.082967 0.071655 0.061439 0.04956 0.053584 0.057052 0.068018 0.038626 0.010469 0.0026049 0.00062774 0.00043022 0.0005539 0.00035057
                    ];
            case 25
                    cam_sen = [
                    0.00069598 0.0017955 0.03849 0.032667 0.022494 0.018328 0.013315 0.0098982 0.0085853 0.010046 0.012832 0.012527 0.016817 0.024193 0.032005 0.042986 0.029588 0.02875 0.024543 0.047067 0.24784 0.51222 0.56765 0.53089 0.47212 0.47652 0.43985 0.43999 0.38837 0.35857 0.14976 0.022566 0.0052279
                    0.0003502 0.00095076 0.027529 0.035843 0.040188 0.053272 0.0633 0.075669 0.10131 0.15071 0.19793 0.21325 0.2719 0.38335 0.43669 0.50591 0.47089 0.45974 0.39171 0.3586 0.27635 0.21887 0.13822 0.081378 0.050058 0.041537 0.035448 0.034529 0.032905 0.03965 0.02311 0.0044686 0.0012376
                    0.0059998 0.014903 0.33048 0.5159 0.593 0.77856 0.85093 0.95348 1 0.97 0.90455 0.74081 0.53426 0.38896 0.22431 0.15749 0.10207 0.066248 0.053148 0.048638 0.037498 0.028947 0.017555 0.010178 0.006669 0.0064568 0.0085921 0.013675 0.018137 0.022108 0.010653 0.0019601 0.00073669
                    ];
            case 26
                    cam_sen = [
                    0.019018 0.014402 0.0098499 0.007959 0.0064246 0.0041105 0.0036892 0.0045871 0.0063732 0.0041453 0.0059531 0.012529 0.031461 0.052841 0.029951 0.013065 0.014721 0.061239 0.31181 0.57365 0.60673 0.60505 0.56097 0.59012 0.52696 0.53172 0.4627 0.30719 0.10616 0.045747 0.021471 0.0078361 0.0078361
                    0.01747 0.023179 0.028369 0.040462 0.050979 0.065752 0.090673 0.142 0.2015 0.21978 0.27836 0.39334 0.46231 0.54895 0.53346 0.52956 0.45686 0.4006 0.31136 0.23003 0.12463 0.052939 0.020602 0.011267 0.0065 0.0037935 0.0040276 0.0062781 0.0047804 0.0036197 0.0025212 0.0011495 0.0011495
                    0.22432 0.39809 0.48749 0.67884 0.7892 0.93021 0.99708 1 0.99081 0.87084 0.7094 0.5394 0.29909 0.15304 0.061858 0.015181 0 0 0 0 1.4374e-05 3.2486e-05 0.00026582 0.00062954 0.00065404 0.0017766 0.0022672 0.0020995 0.00074893 0.0003254 0.00020542 6.2558e-05 6.2558e-05
                    ];
            case 27
                    cam_sen = [
                    0.010464 0.015837 0.022809 0.029193 0.032943 0.042109 0.048271 0.054768 0.055121 0.048086 0.037059 0.037067 0.052124 0.064936 0.076516 0.13492 0.29332 0.63001 0.7694 0.81813 0.65358 0.52142 0.37956 0.2838 0.18967 0.1305 0.078487 0.042293 0.023358 0.012703 0.0063621 0.0033125 0.0017011
                    0.0064171 0.013114 0.025186 0.033325 0.045721 0.073911 0.11369 0.17692 0.26413 0.41186 0.5986 0.75879 0.91359 1 0.90399 0.77751 0.55129 0.41299 0.30832 0.20757 0.10815 0.059445 0.030895 0.018277 0.01124 0.0068513 0.0034711 0.00181 0.001035 0.00060223 0.00034704 0.00023128 0.00015694
                    0.086173 0.15791 0.26574 0.37978 0.42988 0.50637 0.52789 0.55929 0.53494 0.48996 0.40612 0.30199 0.25274 0.20297 0.14868 0.11294 0.077274 0.057152 0.044852 0.038781 0.027546 0.021149 0.015703 0.012548 0.0094433 0.007636 0.0054527 0.0033028 0.0020177 0.0012756 0.00078306 0.00052376 0.00031011
                    ];
            case 28
                    cam_sen = [
                    0.0073643 0.055237 0.051835 0.043321 0.033681 0.028963 0.025 0.031318 0.034458 0.033059 0.036819 0.04791 0.075209 0.083833 0.040534 0.025882 0.029435 0.096315 0.40981 0.59492 0.48306 0.4419 0.32839 0.26576 0.18549 0.14261 0.10679 0.073901 0.045969 0.011987 0.0019017 0.00074491 0.00024202
                    0.0087465 0.075143 0.10312 0.12927 0.14942 0.19179 0.24858 0.37672 0.45492 0.50906 0.67036 0.85874 0.93855 1 0.87676 0.85895 0.66097 0.54573 0.3987 0.29141 0.14386 0.086686 0.046569 0.032661 0.021849 0.016681 0.013952 0.012859 0.011204 0.0038035 0.00078707 0.00032949 0.00013348
                    0.033016 0.35254 0.49797 0.60149 0.65736 0.78336 0.73926 0.776 0.72276 0.61365 0.4557 0.30535 0.17946 0.12249 0.073361 0.04487 0.020265 0.012304 0.0085751 0.0064746 0.0032885 0.002511 0.0020362 0.0023356 0.0027482 0.0036074 0.0036988 0.0031634 0.0022407 0.00069044 0.00012112 6.3737e-05 4.2452e-05
                    ];
            case 29 % Canon 650D
                    cam_sen = [0.0592701667127317,0.313027139239136,2.78908583395609;0.0283438233949440,0.972172595414418,5.16182128673788;0.265858027995478,5.34243538332240,3.61315079556403;0.807650839855656,5.91305309212547,0.746756609541909;3.02777833934224,4.19228869445417,0.272080097992987;2.68907744488519,0.562506352120694,0.0700661833495584;1.11652449163423,0.136516309494670,0.0616344079310329]';
                    Camera.lambda = 420 : 40 : 660;
                
        end
        
        % Save raw data
        Camera.Sen_orig = cam_sen';
        Camera.lam_orig = Camera.lambda;
        
        % Standardize domain
        cam_sen = cam_sen';
        Camera.sensitivity = zeros(length(Wavelength), 3);
        for cc = 1 : 3
            Camera.sensitivity(:,cc) = interp1(Camera.lambda, cam_sen(:,cc), Wavelength);
        end
        Camera.lambda = Wavelength;
        
        update_sensor
        
        figure(3)
            set(gcf,'Name','Camera','NumberTitle','off')
            clf
            hold on
            set(gcf,'color','white')
            for cc = 1:3
                col = [0 0 0];
                col(cc) = 1;
                plot(Camera.lambda, Camera.sensitivity(:,cc), 'Color', col,'LineWidth',2)
            end
            grid on
            grid minor
            xlabel('Wavelength, nm')
            ylabel('Sensitivity, ~')
            title(['Camera: ' Camera.description])
            xlim(lambda_lims)
            ylim([0 max(ylim)])
        
    end
    
end


















































