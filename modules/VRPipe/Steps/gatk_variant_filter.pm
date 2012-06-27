use VRPipe::Base;

#Example VariantFiltration command - GATK v1.3
#java -Xmx2g -jar GenomeAnalysisTK.jar \
#   -R ref.fasta \
#   -T VariantFiltration \
#   -o output.vcf \
#   --variant input.vcf \
#   --filterExpression "AB < 0.2 || MQ0 > 50" \
#   --filterName "Nov09filters" \
#   --mask mask.vcf \
#   --maskName InDel

class VRPipe::Steps::gatk_variant_filter extends VRPipe::Steps::gatk {
    around options_definition {
        return { %{$self->$orig},
                 reference_fasta => VRPipe::StepOption->get(description => 'absolute path to reference genome fasta'),
                 var_filter_opts => VRPipe::StepOption->get(description => 'options for GATK VariantFiltration, excluding reference genome, input and output'),
               };
    }

    method inputs_definition {
        return { vcf_files => VRPipe::StepIODefinition->get(type => 'vcf', max_files => -1, description => 'one or more tabixed vcf files for hard-filtering variant calls'),
		};
    }

    method body_sub {
        return sub {
            my $self = shift;
            my $options = $self->options;
	    $self->handle_standard_options($options);
            
            my $var_filter_opts = $options->{var_filter_opts};
	    my $reference_fasta = $options->{reference_fasta};
	    
	    $self->set_cmd_summary(VRPipe::StepCmdSummary->get(exe => 'GenomeAnalysisTK', 
							       version => $self->gatk_version(),
							       summary => 'java $jvm_args -jar GenomeAnalysisTK.jar -T VariantFiltration -R $reference_fasta --variant $vcf_path -o $vcf_filt_path '.$var_filter_opts));
	    
            my $req = $self->new_requirements(memory => 1200, time => 1);
            my $jvm_args = $self->jvm_args($req->memory);
	    
            foreach my $vcf (@{$self->inputs->{vcf_files}}) {
                my $vcf_path = $vcf->path->stringify;
		my $basename = $vcf->basename;
		if ($basename =~ /\.vcf.gz$/) {
		    $basename =~ s/\.vcf.gz$/.filt.vcf.gz/;
		}
		else {
		    $basename =~ s/\.vcf$/.filt.vcf/;
		}
		
		my $vcf_filt_file = $self->output_file(output_key => 'filtered_vcf_files', basename => $basename, type => 'vcf', metadata => {%{$vcf->metadata}, source_vcf => $vcf_path});
		my $vcf_filt_path = $vcf_filt_file->path;
		
		my $cmd = $self->java_exe.qq[ $jvm_args -jar ].$self->jar.qq[ -T VariantFiltration -R $reference_fasta --variant $vcf_path -o $vcf_filt_path $var_filter_opts ];
		$self->dispatch([$cmd, $req, {output_files => [$vcf_filt_file]}]); 
	    }
        };
    }
    method outputs_definition {
        return { filtered_vcf_files => VRPipe::StepIODefinition->get(type => 'vcf', max_files => -1, description => 'a hard-filtered vcf file for each input vcf') };
    }
    method post_process_sub {
        return sub { return 1; };
    }
    method description {
        return "Run gatk VariantFiltration of vcf files, generating hard-filtered vcfs";
    }
    method max_simultaneous {
        return 0; # meaning unlimited
    }
}

1;
