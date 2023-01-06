require "tempfile"

def create_uml_class(in_dir, out_file)
  out = []
  out.push "@startuml"

  puts "in_dir = #{in_dir}"
  main_composition_list = []
  main_method_list = []
  global_var = []

  Dir.glob("#{in_dir}/**/*.{rb,ru}") do |f|
    puts f
    buf = ""
    Tempfile.create("rufo") do |tmp_file|
      pp tmp_file.path
      FileUtils.cp(f, tmp_file.path)
      open("|rufo #{tmp_file.path}") do |f|
        if f.read =~ /error/
          puts "rufo error #{f}"
          return
        else
          buf = File.binread tmp_file.path
        end
      end
    end

    #puts buf
    inherit_list = []
    composition_list = []
    out_class_list = []
    out_module_list = []
    class_list = []
    block_count = 0
    method_type = :public
    class_name = ""
    # ソースを解析
    buf.each_line do |line|
      next if line =~ /^$/  # 空行は対象外

      # ブロックの開始/終了
      indent_num = line.match(/^[ ]+/).to_s.size / 2
      if block_count == indent_num
        # 変化なし
      elsif block_count > indent_num
        # ブロックの終了
        block_count = indent_num
      else
        # ブロックの開始
        block_count = indent_num
      end

      #line.gsub!(/\".+\"/, "\"delete_string\"") # 文字列を削除
      if line =~ /^\s*class\s/
        unless line =~ /<</ # 特異クラスではない
          work = line.gsub(/class\s/, "")
          class_name = work.split("<")[0].to_s.chomp.match(/[A-Z][A-Za-z0-9_]+/).to_s
          base_name = work.split("<")[1].to_s.chomp.match(/[A-Z][A-Za-z0-9_]+/).to_s
          if base_name != ""
            inherit_list.push "#{class_name} --|> #{base_name}"
          end
          class_list.push [:class, class_name, block_count, [], []]
        end
        next
      elsif line =~ /^\s*module\s/
        module_name = line.split(" ")[1].to_s.chomp
        module_name.gsub!(/^[:]+/, "")
        class_list.push [:module, module_name, block_count, [], []]
        next
      end

      if line =~ /^\s*def\s/
        # 関数名を取り出す
        method = line.chomp.gsub(/\s*def\s*/, "")
        unless method =~ /\(/
          # 関数名にカッコをつける
          sp = method.split(" ")
          if sp.size > 1
            method = sp[0].to_s + "(" + sp[1..-1].to_s + ")"
          else
            method = method + "()"
          end
        end
        if class_list.size != 0
          method_list = class_list[-1][4]
          case method_type
          when :public
            method_list.push "+ #{method}"
          when :private
            method_list.push "- #{method}"
          when :protected
            method_list.push "# #{method}"
          end
        else
          main_method_list.push "+ #{method}"
        end
      end

      # composition_list
      line.match(/(([\/\"\')].*?\.new.*?[\/\"\'])|(?![\/\"\'])([a-zA-Z0-9_]+\.new))/) do |m|
        if m.to_s[0] != "/" and m.to_s[0] != "\"" and m.to_s[0] != "'"
          name = m.to_s.gsub(/\.new/, "").match(/[A-Z][A-Za-z0-9_]+/).to_s
          if name != ""
            if class_list.size != 0
              composition_list.push "#{class_list[-1][1]} *-- #{name}"
            else
              main_composition_list.push "main *-- #{name}"
            end
          end
        end
      end

      # インスタンス変数
      if line =~ /\s*@\S+/
        if class_list.size != 0
          line.match(/@[a-zA-Z0-9_]+/) { |m|
            instance_var = class_list[-1][3]
            val = m.to_s.gsub(/@/, "")
            case method_type
            when :public
              instance_var.push "+ #{val}"
            when :private
              instance_var.push "- #{val}"
            when :protected
              instance_var.push "# #{val}"
            end
          }
        end
      end

      # 外部変数
      line.match(/\$[a-zA-Z0-9_]+/) { |m|
        global_var.push "+ #{m.to_s}"
      }

      # クラスの終了
      if class_list.size != 0
        puts "#{block_count} #{line.chomp}"
        #puts "#{block_count} #{line.chomp} <=> #{class_list[-1][2]}"
        if block_count == class_list[-1][2] # block_countが一致
          puts "end of #{class_list[-1][1]}"
          if class_list[-1][0] == :class
            out_class_list.push class_list[-1]
          else
            out_module_list.push class_list[-1]
          end
          class_list.slice!(-1) # 最後の要素を削除
        end
      end
      #puts "#{block_count} #{line.chomp}"
    end
    if block_count != 0
      # エラー
      puts f
      return ""
    end

    # namespaceの開始
    out_module_list.reverse.each do |m_list|
      instance_var = m_list[3]
      method_list = m_list[4]
      out.push "namespace #{m_list[1]} {"
      # インスタンス変数がある場合はモジュール名と同じクラスを定義
      if instance_var.size != 0 or method_list.size != 0
        out.push "class #{m_list[1]} {"
      end
      # インスタンス変数の出力
      if instance_var != nil
        instance_var.uniq.each do |iv|
          out.push iv
        end
      end
      # メソッドの出力
      if method_list != nil
        method_list.each do |ml|
          out.push ml
        end
      end
      if instance_var.size != 0 or method_list.size != 0
        out.push "}"
      end
    end

    # クラスの出力
    out_class_list.reverse.each do |c_list|
      out.push "class #{c_list[1]} {"
      # インスタンス変数の出力
      instance_var = c_list[3]
      if instance_var != nil
        instance_var.uniq.each do |iv|
          out.push iv
        end
      end
      # メソッドの出力
      method_list = c_list[4]
      if method_list != nil
        method_list.each do |ml|
          out.push ml
        end
      end
      out.push "}"
    end

    # 継承リストの出力
    inherit_list.each do |il|
      out.push il
    end
    # composition_listの出力
    composition_list.uniq.each do |cl|
      out.push cl
    end

    # namespaceの終了
    out_module_list.reverse.each do |m_list|
      out.push "}"
    end
  end

  if main_method_list.size != 0
    out.push "class main {"
    main_method_list.each do |mml|
      out.push mml
    end
    # グローバル変数の出力
    global_var.uniq.each do |gv|
      out.push gv
    end
    out.push "}"
    main_composition_list.each do |mcl|
      out.push mcl
    end
  end

  out.push "@enduml"
  return out.join("\n")
end
