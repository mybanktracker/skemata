require 'json'
require 'ostruct'

describe Skemata::DSL do
  let(:cat) do 
    OpenStruct.new(
      name: 'Dr. Snuggles',
      age: 10,
      occupation: 'Sleep expert'
    )
  end

  let(:opts) do 
    { root_object: cat, type: :Animal }
  end

  let(:schema_definition) do
    described_class.draw(opts) do 
      name
      age
      occupation
    end
  end

  let(:result) { JSON.parse(schema_definition) }

  context '.draw' do
    it 'should produce JSON with the correct attributes' do
      expect(result).to eql(
        { "@type" => opts[:type].to_s,
          "@context" => "https://schema.org",
          "name" => cat.name,
          "age" => cat.age,
          "occupation" => cat.occupation } 
      )
    end

    context 'with a hash and primitive object attributes' do 
      let(:opts) { { root_object: { foo: 'bar'}, type: 'Baz' } }
      let(:schema_definition) do 
        described_class.draw(opts) do
          foo
          not_a_thing 'except it is now'
        end
      end

      it 'should produce a valid schema' do
        expect(result).to eql(
          { "@type" => opts[:type].to_s,
            "@context" => "https://schema.org",
            "foo" => "bar",
            "not_a_thing" => "except it is now" }
        )
      end
    end

    context 'with nesting' do 
      context 'n-ary distant properties' do  
        before { cat.toy = OpenStruct.new(color: 'red') }

        let(:schema_definition) do 
          described_class.draw(opts) do 
            name
            age
            toy_color nested :toy, :color
            occupation
          end
        end

        it 'should produce a valid schema' do
          expect(result).to eql(
            { "@type" => opts[:type].to_s,
              "@context" => "https://schema.org",
              "name" => cat.name,
              "age" => cat.age,
              "toy_color" => cat.toy.color,
              "occupation" => cat.occupation }
          )
        end
      end

      context 'child objects' do
        before do 
          cat.best_friend = OpenStruct.new(
            name: 'Garfield',
            age: 8,
            occupation: 'Lasagna expert, likes playing with yarn'
          )
        end

        let(:schema_definition) do 
          described_class.draw(opts) do 
            name
            age
            occupation

            best_friend :Animal do 
              name
              age
              occupation
            end
          end
        end

        it 'should produce a valid schema' do 
          expect(result['best_friend']).to eql(
            { "@type" => opts[:type].to_s,
              "name" => cat.best_friend.name,
              "age" => cat.best_friend.age,
              "occupation" => cat.best_friend.occupation }
          )

          expect(result['best_friend']).to_not have_key('@context')
        end
      end
    end
  end
end