# Physically-Based Rendering extension for SketchUp 2017 or newer.
# Copyright: © 2018 Samuel Tallet-Sabathé <samuel.tallet@gmail.com>
# 
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3.0 of the License, or
# (at your option) any later version.
# 
# If you release a modified version of this program TO THE PUBLIC,
# the GPL requires you to MAKE THE MODIFIED SOURCE CODE AVAILABLE
# to the program's users, UNDER THE GPL.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# General Public License for more details.
# 
# Get a copy of the GPL here: https://www.gnu.org/licenses/gpl.html

raise 'The PBR plugin requires at least Ruby 2.2.0 or SketchUp 2017.'\
  unless RUBY_VERSION.to_f >= 2.2 # SketchUp 2017 includes Ruby 2.2.4.

require 'sketchup'
require 'pbr/material_editor'
require 'pbr/viewport'
require 'fileutils'
require 'pbr/gltf'

# PBR plugin namespace.
module PBR

  # Connects PBR plugin menu to SketchUp user interface.
  class Menu

    # Adds PBR plugin menu (items included) in a SketchUp menu.
    #
    # @param [Sketchup::Menu] parent_menu Target parent menu.
    # @raise [ArgumentError]
    def initialize(parent_menu)

      raise ArgumentError, 'Parent menu must be a SketchUp::Menu.'\
        unless parent_menu.is_a?(Sketchup::Menu)

      @menu = parent_menu.add_submenu(NAME)

      add_edit_materials_item

      add_reopen_viewport_item

      add_export_as_gltf_item

      add_donate_to_author_item

    end

    # Adds "Edit Materials..." menu item.
    #
    # @return [void]
    private def add_edit_materials_item

      @menu.add_item('⬕ ' + TRANSLATE['Edit Materials...']) do

        Menu.edit_materials
        
      end

    end

    # Runs "Edit Materials..." menu command.
    #
    # @return [void]
    def self.edit_materials

      # Show Material Editor if all good conditions are met.
      MaterialEditor.new.show if MaterialEditor.safe_to_open?

    end

    # Adds "Reopen Viewport" menu item.
    #
    # @return [void]
    private def add_reopen_viewport_item

      @menu.add_item(TRANSLATE['Reopen Viewport']) do

        return PBR.open_required_plugin_page unless PBR.required_plugin_exist?

        Menu.reopen_viewport

      end

    end

    # Adds "Export As 3D Object..." menu item.
    #
    # @return [void]
    private def add_export_as_gltf_item

      @menu.add_item(TRANSLATE['Export As 3D Object...']) do

        return PBR.open_required_plugin_page unless PBR.required_plugin_exist?

        Menu.export_as_gltf

      end

    end

    # Runs "Reopen Viewport" menu command.
    #
    # Note: This only updates glTF model asset.
    #
    # @return [void]
    def self.reopen_viewport

      propose_nil_material_fix

      propose_help(TRANSLATE['glTF export failed. Do you want help?'])\
        unless Viewport.update_model

      Viewport.reopen

    end

    # Runs "Export As 3D Object..." menu command.
    #
    # @return [void]
    def self.export_as_gltf

      propose_nil_material_fix

      user_path = UI.savepanel(TRANSLATE['Export As glTF'], nil, GlTF.filename)

      # Escape if user cancelled export operation.
      return if user_path.nil?

      gltf = GlTF.new

      if gltf.valid?

        File.write(user_path, gltf.json)
        UI.messagebox(TRANSLATE['Model well exported here:'] + "\n#{user_path}")

      else
        
        propose_help(TRANSLATE['glTF export failed. Do you want help?'])

      end

    end

    # Proposes "nil material" fix to SketchUp user.
    #
    # @return [void]
    def self.propose_nil_material_fix

      user_answer = UI.messagebox(
        TRANSLATE['Propagate materials to whole model? (Recommended)'],
        MB_YESNO
      )

      # Escape if user refused that fix.
      return if user_answer == IDNO

      require 'pbr/nil_material_fix'

      # Apply "nil material" fix.
      NilMaterialFix.new(TRANSLATE['Propagate Materials to Whole Model'])

    end

    # Proposes help to SketchUp user.
    #
    # @param [String] message Help proposal message.
    #
    # @return [void]
    def self.propose_help(message)

      user_answer = UI.messagebox(message, MB_YESNO)

      # Escape if user refused that help.
      return if user_answer == IDNO

      require 'pbr/github'

      # Open help of PBR plugin in default Web browser.
      UI.openURL(GitHub.translated_help_url('SKETCHUP'))

    end

    # Adds "Donate to Plugin Author" menu item.
    #
    # @return [void]
    private def add_donate_to_author_item

      @menu.add_item('💌 ' + TRANSLATE['Donate to Plugin Author']) do

        UI.openURL('https://www.paypal.me/SamuelTS/')
        
      end

    end

  end

end
