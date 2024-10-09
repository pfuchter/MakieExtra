function zoom_lines!(ax1, ax2; strokewidth=1.5, strokecolor=:black, color=(:black, 0))
	pscene = parent(parent(Makie.parent_scene(ax1)))
	@assert parent(parent(Makie.parent_scene(ax2))) === pscene
	obs = @lift let
		lims = [$(ax1.finallimits), $(ax2.finallimits)]
		vps = [$(ax1.scene.viewport), $(ax2.scene.viewport)]
		axs = lims[1] ⊆ lims[2] ? (
			(vp=vps[1], lim=lims[1]),
			(vp=vps[2], lim=lims[2]),
		) : lims[2] ⊆ lims[1] ? (
			(vp=vps[2], lim=lims[2]),
			(vp=vps[1], lim=lims[1]),
		) : nothing

		
		#check if either ax is completely inside the other:
		ax1insideax2 = vps[1] ⊆ vps[2]
		ax2insideax1 = vps[2] ⊆ vps[1]
		if isnothing(axs)
			fs = nothing
		else
		if ax2insideax1 || ax1insideax2
			Ax1 = ax2insideax1 ? axs[2] : axs[1]
			Ax2 = ax2insideax1 ? axs[1] : axs[2]
			Ax1 = axs[2]
			Ax2 = axs[1]
			rect_bottomleft = shift_range(bottomleft(Ax2.lim), Ax1.lim => Ax1.vp)
			rect_topright   = shift_range(topright(Ax2.lim), Ax1.lim => Ax1.vp)
			
			rect_left = rect_bottomleft[1]
			rect_right = rect_topright[1]
			rect_top = rect_topright[2]
			rect_bottom = rect_bottomleft[2]

			fs = isnothing(axs) ? nothing : if rect_right < left(Ax2.vp)
				(topleft, bottomleft, topright, bottomright)
			elseif rect_left > right(Ax2.vp)
				(topright, bottomright, topleft, bottomleft)
			elseif rect_top < bottom(Ax2.vp)
				(bottomleft, bottomright, topleft, topright)
			elseif rect_left < right(Ax2.vp)
				(topleft, topright, bottomleft, bottomright)
			end
		else
			fs = isnothing(axs) ? nothing : if right(axs[1].vp) < left(axs[2].vp)
				(topright, bottomright, topleft, bottomleft)
			elseif left(axs[1].vp) > right(axs[2].vp)
				(topleft, bottomleft, topright, bottomright)
			elseif bottom(axs[1].vp) > top(axs[2].vp)
				(bottomleft, bottomright, topleft, topright)
			elseif bottom(axs[1].vp) < top(axs[2].vp)
				(topleft, topright, bottomleft, bottomright)
			end
		end
	end
		# display(lims)
		(
			rect1=$(ax2.finallimits),
			rect2=$(ax1.finallimits),
			slines=isnothing(axs) || isnothing(fs) ? Point2{Float32}[] : [
				fs[1](axs[1].vp), shift_range(fs[3](axs[1].lim), axs[2].lim => axs[2].vp),
				fs[2](axs[1].vp), shift_range(fs[4](axs[1].lim), axs[2].lim => axs[2].vp),
			],
		)
	end

	rectattrs = (; strokewidth, strokecolor, color, xautolimits=false, yautolimits=false)
	poly!(ax1, (@lift $obs.rect1); rectattrs...)
	poly!(ax2, (@lift $obs.rect2); rectattrs...)
	plt = linesegments!(pscene, (@lift $obs.slines), color=strokecolor, linewidth=strokewidth, linestyle=:dot)
	translate!(plt, 0, 0, 1000)
	return nothing
end
