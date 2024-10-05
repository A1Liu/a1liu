import { ZodRawShape } from "zod";

export class FormPage<In extends ZodRawShape, Out extends In> {
  constructor(
    private readonly schema: Omit<Out, keyof In>,
    private readonly parent?: FormPage<{}, In>
  ) {}

  next<NewOut extends Out>(
    schema: Omit<NewOut, keyof Out>
  ): FormPage<Out, NewOut> {
    return new FormPage<Out, NewOut>(schema, this as any as FormPage<{}, Out>);
  }
}

/*
 * Expected use:
 *
 * interface Context {
 *  nextButtonText: string
 * }
 *
 * const formDef = new FormDef<Context>();
 * const page1Def = formDef.next({
 *  chooseNextPage: ({ params: { field1, field2 } }) => {
 *    return page2Def;
 *  },
 *  validate: ({ params: { field1, field2 } }) => {
 *    return field1 === field2
 *  },
 *  schema: {
 *   field1: z.string(),
 *   field2: z.string(),
 *  },
 *  context: {
 *    nextButtonText: string,
 *  }
 * })
 * const page2Def = page1Def.next({
 *  schema: {
 *   field3: z.string(),
 *   field4: z.string(),
 *  },
 *  context: {
 *    nextButtonText: string,
 *  }
 * })
 *
 * function Form() {
 * return <FormContext>
 *          <Page1 />
 *          <Page2 />
 *          <Page3 />
 *          {
 *          // or whatever else
 *          }
 *          <CommonUI />
 *       </FormContext>
 * }
 *
 * function Page1() {
 *   const { isValid, fields, nextPage } = useFormPage(page1Def)
 * }
 *
 * function CommonUI() {
 *   const { pageIsValid, pageDef, nextPage } = useFormStatus(formDef)
 *
 *   return (
 *      <div>
 *        <button disabled={!pageIsValid} onClick={() => {
 *          const {} = nextPage()
 *        }}>
 *          {pageDef.context.nextButtonText}
 *        </button>
 *      </div>
 *   )
 *
 * }
 */
