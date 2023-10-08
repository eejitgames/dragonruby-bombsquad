$gtk.reset

class BombSquadGame
  def initialize args
    @args = args
    @bomb_timer = 21 # +1 to show timer start at 20
    @game_over = false
    @cutter_frame = 0
    @start_looping_at = 0
    @number_of_sprites = 3
    @number_of_frames_to_show_each_sprite = 18
    @mouse_position = []
    @cutter_box = []
    @is_cutting = false
    @defused_bomb = false
    @exploded_bomb = false
    @args.state.clipper.min_ang = -1
    @args.state.clipper.max_ang = 10.5
    @args.state.clipper.curr_ang = 0
    @args.state.clipper.dir = 0.4
    @end_delay = 0
    @end_scene = 0
    @wire_count = 1
    @screen_x = 0
    @screen_y = 0
    @screen_angle = 0
    @color_index = [
	    [ 255, 255, 255 ],
	    [ 255, 0, 0 ],
	    [ 0, 255, 0 ],
	    [ 0, 0, 255 ],
	    [ 255, 255, 0 ],
      [0, 0, 0]
	  ]
    random_order = [1, 2, 3, 4, 5].shuffle
    wire_y_coord = [200, 300, 400, 500, 600].shuffle
    @wires = {
      "white"=> {
        c: @color_index[0], 
        x: 800, 
        y: wire_y_coord[0], 
        s: random_order[0],
        l: 60
      },
      "red"=>  {
        c: @color_index[1], 
        x: 800, 
        y: wire_y_coord[1], 
        s: random_order[1],
        l: 60
      },
      "green"=> {
        c: @color_index[2], 
        x: 800, 
        y: wire_y_coord[2], 
        s: random_order[2],
        l: 60
      },
      "blue"=> {
        c: @color_index[3], 
        x: 800, 
        y: wire_y_coord[3], 
        s: random_order[3],
        l: 60
      },
      "yellow"=> {
        c: @color_index[4], 
        x: 800, 
        y: wire_y_coord[4], 
        s: random_order[4],
        l: 60
      }
    }
  end
  
  def countdown_timer
    k = @args.inputs.keyboard
    c = @args.inputs.controller_one
	
    if @game_over == true
      # whew ! you defused the bomb !
      @args.outputs.labels << [ 175, 450, "You defused the bomb !", 40, 255, 255, 255, 255 ] if @defused_bomb == true
      @args.outputs.labels << [ 425, 100, "press space to play again", 10, 255, 255, 255, 255 ] if @defused_bomb == true
      # you blew it !
      if @exploded_bomb == true
        case @end_scene
        when 0 # show the white hot bomb for a moment
          @end_delay += 1
          if @end_delay > 5
            @end_delay = 0
            @end_scene = 1
            @args.audio.delete(:flatline)
          end
        when 1 # screen that fades quickly to red
          @args.outputs.background_color = [ 255, 255 - (@end_delay * 8.5), 255 - (@end_delay * 8.5) ]
          @end_delay += 2.5
          if @end_delay == 25
            # nuclear blast from audiosoundclips.com
            @args.audio[:explosion] = {
              input: 'sounds/explosion.wav',  # Filename
              x: 0.0, y: 0.0, z: 0.0,      # Relative position to the listener, x, y, z from -1.0 to 1.0
              gain: 0.5,                   # Volume (0.0 to 1.0)
              pitch: 1.0,                  # Pitch of the sound (1.0 = original pitch)
              paused: false,               # Set to true to pause the sound at the current playback position
              looping: false,              # Set to true to loop the sound/music until you stop it
            }
          end
          if @end_delay > 30
            @end_delay = 0
            @end_scene = 2
          end
        when 2 # fades quickly to this image
          @args.outputs.background_color = [ 255, 0, 0 ]
          # from the atomicarchive.com
          @args.outputs.sprites << { x: 0, y: 0, w: 1280, h: 720, path: "sprites/mushroom/mushroom-cloud.png", a: @end_delay * 8.5 }
          @end_delay += 0.1
          if @end_delay > 30
            @end_delay = 0
            @end_scene = 3
          end  
        when 3 # fades quickly to black
          @args.outputs.background_color = [ 0, 0, 0 ]
          @args.outputs.sprites << { x: 0, y: 0, w: 1280, h: 720, path: "sprites/mushroom/mushroom-cloud.png", a: 255 - @end_delay * 8.5 }
          @end_delay += 0.2
          if @end_delay > 27
            @args.outputs.labels << [ 200, 450, "GAME OVER", 100, 255, 255, 255, 255 ]  
          end
          if @end_delay > 30
            @end_delay = 0.5
            @end_scene = 4
          end
        when 4 # fade out explosion sound, game over
          @args.outputs.background_color = [ 0, 0, 0 ]
          @args.outputs.labels << [ 200, 450, "GAME OVER", 100, 255, 255, 255, 255 ]  
          @args.audio[:explosion].gain = @end_delay if @end_delay >= 0
          @end_delay -= 0.0085
          if @end_delay < 0
            @args.audio.delete :explosion
            @end_scene = 5
          end
        when 5 # game over
          @args.outputs.background_color = [ 0, 0, 0 ]
          @args.outputs.labels << [ 200, 450, "GAME OVER", 100, 255, 255, 255, 255 ]
          @args.outputs.labels << [ 425, 100, "press space to play again", 10, 255, 255, 255, 255 ]
        end
      end

      if k.key_down.space || c.key_down.start
        $gtk.reset(seed: Time.now.to_i)
      end
      return
    end
	  # cool sounds provided by Pineapple
    if @args.state.tick_count.mod_zero?(60)
      if @bomb_timer.mod_zero?(2)
        @args.audio[:sound1] = {
          input: 'sounds/sound1.wav',  # Filename
          x: 0.0, y: 0.0, z: 0.0,      # Relative position to the listener, x, y, z from -1.0 to 1.0
          gain: 0.25,                  # Volume (0.0 to 1.0)
          pitch: 1.0,                  # Pitch of the sound (1.0 = original pitch)
          paused: false,               # Set to true to pause the sound at the current playback position
          looping: false,              # Set to true to loop the sound/music until you stop it
        }
      else
        @args.audio[:sound2] = {
          input: 'sounds/sound2.wav',  # Filename
          x: 0.0, y: 0.0, z: 0.0,      # Relative position to the listener, x, y, z from -1.0 to 1.0
          gain: 0.25,                  # Volume (0.0 to 1.0)
          pitch: 1.0,                  # Pitch of the sound (1.0 = original pitch)
          paused: false,               # Set to true to pause the sound at the current playback position
          looping: false,              # Set to true to loop the sound/music until you stop it
        }
      end
      @bomb_timer -= 1
    end

    if @bomb_timer <= 0 
      @bomb_timer = 0
      @game_over = true
      @exploded_bomb = true
    end
  end
  
  def rt_background
    @args.outputs.background_color = [ 127, 127, 127 ]
  end

  def rt_bomb
    if @exploded_bomb == true
      @args.render_target(:bomb).sprites << { x: 50, y: 0, w: 751, h: 768, path: 'sprites/bomb/white-bomb.png' }  
    else
      @args.render_target(:bomb).sprites << { x: 50, y: 0, w: 751, h: 768, path: 'sprites/bomb/bomb.png' }
    end
  end

  def rt_timer
    # font from https://www.keshikan.net/fonts-e.html
    segments = []
    segments << { x: 10, y: 75, text: "88:88", size_enum: 8, alignment_enum: 0, r: 255, g: 0, b: 0, a: 50, font: "fonts/DSEG7Classic-Italic.ttf" }
    segments << { x: 10, y: 75, text: "00:#{'%02d' % @bomb_timer}", size_enum: 8, alignment_enum: 0, r: 255, g: 0, b: 0, a: 255, font: "fonts/DSEG7Classic-Italic.ttf" }
    @args.render_target(:timer).labels << segments
  end
  
  def rt_wires
    output = []
    labels = []
    @wires.each do |color, wire|
	    # puts60 "#{color}: #{wire}, x: #{wire.x}, y: #{wire.y}"
      output << [ wire.x, wire.y, (wire.l * 2), 10, wire.c ]
      labels << [ wire.x + 150, wire.y + 25, "seq #{wire.s}", 10, 0 ,255, 0, 0, 255 ]
    end
    @args.render_target(:wires).solids << output
    @args.render_target(:seq).labels << labels
  end
  
  def rt_combined
    @args.render_target(:combined).sprites << {
      x: 0,
      y: 0,
      w: 1280,
      h: 720,
      path: :bomb
    }
    @args.render_target(:combined).sprites << {
      x: 362,
      y: 574,
      w: 1280,
      h: 720,
      path: :timer,
      angle: 15
    }
    @args.render_target(:combined).sprites << {
      x: 0,
      y: 0,
      w: 1280,
      h: 720,
      path: :wires
    }
  end

  def render_scene
    @screen_x += 1 if @screen_x < 0
    @screen_x -= 1 if @screen_x > 0
    @screen_y += 1 if @screen_y < 0
    @screen_y -= 1 if @screen_y > 0
    @screen_angle += 1 if @screen_angle < 0
    @screen_angle -= 1 if @screen_angle > 0
    @args.outputs.primitives << { x: @screen_x, y: @screen_y, w: 1280, h: 720, path: :combined, angle: @screen_angle}.sprite!
  end

  def check_angle
    if not @args.state.clipper.curr_ang.between? @args.state.clipper.min_ang, @args.state.clipper.max_ang
      @args.state.clipper.curr_ang = @args.state.clipper.curr_ang.clamp @args.state.clipper.min_ang, @args.state.clipper.max_ang
    end
  end

  def use_cutters
    check_angle
    @mouse_position = @args.inputs.mouse.position
    pos = @mouse_position
	  # if mouse is right in the corner, use different coordinates
    # (looks a bit better to start off on html version)
	  if pos.x == 0 and pos.y == 0
	    pos.x = 680
	    pos.y = 360
	  end
	  @cutter_box = [ pos.x - 10, pos.y + 20, 80, 20 ]
	  if @args.inputs.mouse.click
      @start_looping_at = @args.state.tick_count
      @is_cutting = true
    end
    unless @args.inputs.mouse.button_left # .button_bits convert this
      @is_cutting = false
    end
    if @is_cutting == false
      @args.state.clipper.dir = -1
      @args.state.clipper.curr_ang += @args.state.clipper.dir
    end
    rot_x_arm1 = 0.27
    rot_y_arm1 = 0.535
    rot_x_arm2 = 0.27
    rot_y_arm2 = 0.535
    @args.outputs[:clippers].w = 1000
    @args.outputs[:clippers].h = 1000
  
    clipper_bottom = {
      x: 31, y: 152,
      w: 662, h: 441,
      angle_anchor_x: rot_x_arm1,
      angle_anchor_y: rot_y_arm1,
      angle: -@args.state.clipper.curr_ang,
      path: 'sprites/wire-cutters/arm1.png'
    }
  
    clipper_top = {
      x: 33.5, y: 151,
      w: 662, h: 441,
      angle_anchor_x: rot_x_arm2,
      angle_anchor_y: rot_y_arm2,
      angle: @args.state.clipper.curr_ang,
      path: 'sprites/wire-cutters/arm2.png'
    }
  
    @args.outputs[:clippers].sprites << clipper_bottom
    @args.outputs[:clippers].sprites << clipper_top
    @args.outputs.primitives << { x: pos.x - 100, y: pos.y - 280, w: 450, h: 450, path: :clippers, angle: -45 }.sprite!
  end

  def check_wire
    @wires.each do |color, wire|
      if @wires[color].l == 15
        next
      end
	    wire_box = [ wire.x + 100, wire.y, 5, 5 ]
      if @cutter_box.intersect_rect? wire_box
        if @is_cutting == true
          @args.state.clipper.dir = 0.4
          @args.state.clipper.curr_ang += @args.state.clipper.dir
        end    
        @args.outputs.primitives << [ wire.x - 3, wire.y - 3, (wire.l * 2) + 6, 10 + 6, @color_index[5] ].border
        if @args.state.clipper.curr_ang > 10
          @args.audio[:snip] = {
            input: 'sounds/snip.wav',    # Filename
            x: 0.0, y: 0.0, z: 0.0,      # Relative position to the listener, x, y, z from -1.0 to 1.0
            gain: 0.50,                  # Volume (0.0 to 1.0)
            pitch: 1.0,                  # Pitch of the sound (1.0 = original pitch)
            paused: false,               # Set to true to pause the sound at the current playback position
            looping: false,              # Set to true to loop the sound/music until you stop it
          }
          @wires[color][:l] = 15
          @is_cutting = false
          if @wire_count == wire.s
            @wire_count += 1
            if @wire_count > 5
              @defused_bomb = true
              @game_over = true
            end
          else
            @exploded_bomb = true
            @game_over = true
          end
        elsif @args.state.clipper.curr_ang > 3
          if @wire_count != wire.s
            max = 20
            min = -20
            @screen_x = rand * (max - min) + min
            @screen_y = rand * (max - min) + min
            @screen_angle = rand(6) - 3
          end
        end
      end
    end
  end

  def render
    rt_background
    rt_bomb
    rt_timer
    rt_wires
    rt_combined
    render_scene
  end
  
  def tick
    countdown_timer
    if @end_scene == 0
      render
    end

	  if @game_over == true
	    return
	  end

    check_wire
    use_cutters
    # @args.outputs.labels << [ 200, 200, "draw calls: #{$perf_counter_outputs_push_count}", 10, 0, 255, 0, 0, 255 ]
  end
end

def tick args
  args.state.game ||= BombSquadGame.new args
  args.state.game.tick
end
