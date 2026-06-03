using Printf
using LensFactory
using LensFactory.Constants

#Initialising cosmology
cosmo = Cosmology.init_cosmology()

zl = 0.35   #redshift of RMJ1212


DL = Cosmology.luminosity_distance(cosmo, zl)  #in meteres

println(DL)

Dpc= DL/3.085677581e16  #in Parsec
println(Dpc)

DM = 5*log10(Dpc) - 5  #Distance modulus

println("Distance modulus = ", DM)


function main()

  
    # Read X,Y coordinates from DS9 region file
    

    reg_pos = Tuple{Float64,Float64}[]

    open("clustermembers_final.reg", "r") do f
        for line in eachline(f)

            m = match(r"\(([^,]+),([^,]+)", line)

            if m !== nothing
                x = parse(Float64, strip(m.captures[1]))
                y = parse(Float64, strip(m.captures[2]))

                push!(reg_pos, (x, y))
            end
        end
    end

    println("Number of region objects = ", length(reg_pos))

    # Read catalog
    

    header_lines = String[]
    data_lines = String[]

    open("f814w_new.cat", "r") do f

        for line in eachline(f)

            if startswith(line, "#")
                push!(header_lines, line)
            else
                push!(data_lines, line)
            end
        end
    end

    
    # Find X_IMAGE and Y_IMAGE columns
    

    x_col = nothing
    y_col = nothing

    for line in header_lines

        parts = split(strip(line))

        if length(parts) >= 3

            if parts[3] == "X_IMAGE"
                x_col = parse(Int, parts[2])
            end

            if parts[3] == "Y_IMAGE"
                y_col = parse(Int, parts[2])
            end
        end
    end

    if x_col === nothing
        error("X_IMAGE column not found.")
    end

    if y_col === nothing
        error("Y_IMAGE column not found.")
    end

    println("X_IMAGE column = ", x_col)
    println("Y_IMAGE column = ", y_col)

  
    # Match catalog objects to region objects
  

    tolerance = 1.0

    selected = String[]

    for line in data_lines

        vals = split(strip(line))

        xcat = parse(Float64, vals[x_col])
        ycat = parse(Float64, vals[y_col])

        for (xreg, yreg) in reg_pos

            if abs(xcat - xreg) < tolerance &&
               abs(ycat - yreg) < tolerance

                push!(selected, line)
                break
            end
        end
    end

    println("Matched objects = ", length(selected))

   
    # Modify matched rows
    -

    modified_selected = String[]

    for line in selected

        vals = split(strip(line))

        # Insert two 0.0 after column 4
        insert!(vals, 5, "0.0")
        insert!(vals, 6, "0.0")

        # MAG_AUTO is now column 7
        mag_auto = parse(Float64, vals[7])

    # Absolute magnitude
        abs_mag = mag_auto - DM

    # Insert ABS_MAG immediately after MAG_AUTO
        insert!(vals, 8, @sprintf("%.4f", abs_mag))


        # Insert four 0.0 after original MAG_AUTO
        insert!(vals, 9,  "0.0")
        insert!(vals, 10,  "0.0")
        insert!(vals, 11, "0.0")
        insert!(vals, 12, "0.0")

        formatted = join(vals, "   ")

        push!(modified_selected, formatted)
    end

# Sort by apparent magnitude (MAG_AUTO)


sort!(modified_selected, by = line -> begin
    vals = split(line)
    parse(Float64, vals[7])   # MAG_AUTO
end

    # Write output catalog


output_file = "cluster_members_final.cat"

open(output_file, "w") do f

    for line in header_lines
        println(f, line)
    end

    for line in modified_selected
        println(f, line)
    end
end

println("Output saved to: ", output_file)

end

main()    
    

    



