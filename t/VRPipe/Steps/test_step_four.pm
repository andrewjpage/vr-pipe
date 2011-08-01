use VRPipe::Base;

class VRPipe::Steps::test_step_four with VRPipe::StepRole {
    method options_definition {
        return { all_option => VRPipe::StepOption->get(description => 'an option that applies to all steps'),
                 four_option => VRPipe::StepOption->get(description => 'a required option for step four') };
    }
    method inputs_definition {
        return { four_input => VRPipe::StepIODefinition->get(type => 'txt',
                                                             description => 'step four input file',
                                                             metadata => {one_meta => 'metadata we require to appear on our input file, from step one',
                                                                          two_meta => 'metadata we require to appear on our input file, from step two',
                                                                          three_meta => 'metadata we do not require on our input file, from step three, but will handle if present',
                                                                          optional => ['three_meta']}) };
    }
    method body_sub {
        return sub {
            my $self = shift;
            my $options = $self->options;
            my $all_opt = Path::Class::File->new($options->{all_option});
            my $four_opt = $options->{four_option};
            
            $self->set_cmd_summary(VRPipe::StepCmdSummary->get(exe => 'cat',
                                                               version => VRPipe::StepCmdSummary->determine_version('cat --version', '^cat \(GNU coreutils\) (\S+)$'),
                                                               summary => 'cat $input_file > $output_file'));
            
            my $req = $self->new_requirements(memory => 50, time => 1);
            foreach my $in (@{$self->inputs->{four_input}}) {
                my $out = $self->output_file(output_key => 'four_output',
                                             basename => $in->basename.'.step_four',
                                             type => 'txt',
                                             metadata => {one_meta => $in->metadata->{one_meta},
                                                          two_meta => $in->metadata->{two_meta},
                                                          three_meta => $in->metadata->{three_meta} || 'no_three_meta',
                                                          four_meta => $four_opt});
                
                my ($in_path, $out_path) = ($in->path, $out->path);
                my $this_cmd = "cat $in_path > $out_path";
                
                $self->dispatch([$this_cmd, $req, {output_files => [$out]}]);
            }
        };
    }
    method outputs_definition {
        return { four_output => VRPipe::StepIODefinition->get(type => 'txt',
                                                              description => 'step four output file',
                                                              metadata => {one_meta => 'metadata from step one',
                                                                           two_meta => 'metadata from step two',
                                                                           three_meta => 'metadata maybe from step three, otherwise from step four',
                                                                           four_meta => 'metadata applied to step four output file'}) };
    }
    method post_process_sub {
        return sub { return 1; };
    }
    method description {
        return "test step four";
    }
}

1;